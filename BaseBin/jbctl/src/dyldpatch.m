#include <choma/CSBlob.h>
#include <choma/Host.h>
#include <choma/arm64.h>

int apply_dyld_patch(const char *dyldPath, const char *newIdentifier)
{
	MachO *dyldMacho = macho_init_for_writing(dyldPath);
	if (!dyldMacho) return -1;

	// Make AMFI flags always be `0xdf`, allows DYLD_* variables to always work
	__block uint64_t getAMFIAddr = 0;
	macho_enumerate_symbols(dyldMacho, ^(const char *name, uint8_t type, uint64_t vmaddr, bool *stop){
		if (!strcmp(name, "__ZN5dyld413ProcessConfig8Security7getAMFIERKNS0_7ProcessERNS_15SyscallDelegateE")) {
			getAMFIAddr = vmaddr;
		}
	});
	uint32_t getAMFIPatch[] = {
		0xd2801be0, // mov x0, 0xdf
		0xd65f03c0  // ret
	};
	macho_write_at_vmaddr(dyldMacho, getAMFIAddr, sizeof(getAMFIPatch), getAMFIPatch);

	// iOS 16+: Change LC_UUID to prevent the kernel from using the in-cache dyld
	macho_enumerate_load_commands(dyldMacho, ^(struct load_command loadCommand, uint64_t offset, void *cmd, bool *stop) {
		if (loadCommand.cmd == LC_UUID) {
            // The new UUID will look like this:
            // DOPA<dopamine version>\0<rest of original UUID>
            // This way we ensure:
            // - The version it was patched on and it being patched by Dopamine is identifiable later
            // - The UUID is still unique based on the source dyld that was patched

            size_t newIdentifierLen = strlen(newIdentifier) + 1;
            if (newIdentifierLen <= sizeof(uuid_t)) {
                // Also write null byte here, because otherwise it's impossible to know where the version string ends
                macho_write_at_offset(dyldMacho, offset + offsetof(struct uuid_command, uuid), newIdentifierLen, newIdentifier);
            }
            else {
                printf("Error writing identifier to LC_UUID, too long (%zu)\n", newIdentifierLen);
            }
			*stop = true;
		}
	});

	macho_free(dyldMacho);
	return 0;
}