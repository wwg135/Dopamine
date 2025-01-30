#include <choma/CSBlob.h>
#include <choma/Host.h>
#include <choma/arm64.h>

char gDopamineUUID[] = (char[]){'D', 'O', 'P', 'A', 'M', 'I', 'N', 'E', 'D', 'O', 'P', 'A', 'M', 'I', 'N', 'E' };

int apply_dyld_patch(const char *dyldPath)
{
	MachO *dyldMacho = macho_init_for_writing(dyldPath);
	if (!dyldMacho) return -1;

	// Make AMFI flags always be `0xdf`, allows DYLD variables to always work
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

    // Patch loadDyldCache to always map dyld_shared_cache privately, 100% effective workaround against spinlock panics
    /*__block uint64_t loadDyldCacheAddr = 0;
    macho_enumerate_symbols(dyldMacho, ^(const char *name, uint8_t type, uint64_t vmaddr, bool *stop){
        if (!strcmp(name, "__ZN5dyld313loadDyldCacheERKNS_18SharedCacheOptionsEPNS_19SharedCacheLoadInfoE")) {
            loadDyldCacheAddr = vmaddr;
        }
    });

    uint64_t loadDyldCachePatchLocAddr = loadDyldCacheAddr;
    for (; loadDyldCachePatchLocAddr < (loadDyldCacheAddr + (50 * 4)); loadDyldCachePatchLocAddr += 4) {
        uint32_t inst = 0;
        macho_read_at_vmaddr(dyldMacho, loadDyldCachePatchLocAddr, sizeof(inst), &inst);

        arm64_register destReg, addrReg;
        uint64_t imm;
        char type;
        if (arm64_dec_ldr_imm(inst, &destReg, &addrReg, &imm, &type, NULL) == 0) {
            if (ARM64_REG_GET_NUM(addrReg) == 0 && type == 'b') {
                uint32_t nextInst = 0;
                macho_read_at_vmaddr(dyldMacho, loadDyldCachePatchLocAddr+4, sizeof(nextInst), &nextInst);
                bool isCbnz = false;
                if (arm64_dec_cb_n_z(nextInst, loadDyldCachePatchLocAddr+4, &isCbnz, NULL, NULL) == 0) {
                    if (!isCbnz) {
                        break;
                    }
                }
            }
        }
    }

    uint32_t loadDyldCachePatch[] = {
        0xd503201f, // nop
        0xd503201f  // nop
    };
    macho_write_at_vmaddr(dyldMacho, loadDyldCachePatchLocAddr, sizeof(loadDyldCachePatch), loadDyldCachePatch);*/

	// iOS 16+: Change LC_UUID to prevent the kernel from using the in-cache dyld
	macho_enumerate_load_commands(dyldMacho, ^(struct load_command loadCommand, uint64_t offset, void *cmd, bool *stop) {
		if (loadCommand.cmd == LC_UUID) {
			struct uuid_command *uuidCommand = (struct uuid_command *)cmd;
			memcpy(&uuidCommand->uuid, gDopamineUUID, sizeof(gDopamineUUID));
			macho_write_at_offset(dyldMacho, offset, loadCommand.cmdsize, uuidCommand);
			*stop = true;
		}
	});

	macho_free(dyldMacho);
	return 0;
}