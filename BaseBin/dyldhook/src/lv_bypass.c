#include <stdint.h>
#include <stdbool.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <sandbox.h>
#include <fcntl.h>
#include <limits.h>
#include <stdio.h>
#include <sys/mman.h>
#include <libkern/OSByteOrder.h>

#include "machomerger_hook.h"
#include "dyld_jbinfo.h"
#include "dyld.h"

#include <libjailbreak/jbclient_mach.h>
#include <libjailbreak/codesign.h>

// Library validation bypass
// Dyld will call fcntl to attach a code signature to a dylib before mapping it in
// So we hook fcntl to ensure the code signature to be attached is added to trustcache

bool proc_has_bootstrap_port(void)
{
	static bool hasBootstrapPort = false;
	static bool didCheckBootstrapPort = false;

	if (!didCheckBootstrapPort) {
		mach_port_t launchdPort = MACH_PORT_NULL;
		task_get_bootstrap_port(task_self_trap(), &launchdPort);
		if (launchdPort) {
			mach_port_deallocate(task_self_trap(), launchdPort);
		}
		hasBootstrapPort = launchdPort != MACH_PORT_NULL;
		didCheckBootstrapPort = true;
	}

	return hasBootstrapPort;
}

CS_SuperBlob *load_signature(int fd, const fsignatures_t *fs)
{
	uintptr_t superblobStart = fs->fs_file_start + (uintptr_t)fs->fs_blob_start;
	uintptr_t superblobSize  = fs->fs_blob_size;

	vm_address_t addr;
	kern_return_t kr = vm_allocate(mach_task_self(), &addr, superblobSize, VM_FLAGS_ANYWHERE);
	if (kr != KERN_SUCCESS) return NULL;

	lseek(fd, superblobStart, SEEK_SET);
	int r = read(fd, (void *)addr, superblobSize);
	if (r != superblobSize) {
		vm_deallocate(mach_task_self(), addr, superblobSize);
		return NULL;
	}
	CS_SuperBlob *superblob = (CS_SuperBlob *)addr;
	if (OSSwapBigToHostInt32(superblob->length) != superblobSize) {
		vm_deallocate(mach_task_self(), addr, superblobSize);
		return NULL;
	}

	return superblob;
}

int superblob_find_cdflags(const CS_SuperBlob *superblob, off_t *cdflagsOffOut)
{
    const uint8_t *base = (const uint8_t *)superblob;
    uint32_t super_len  = OSSwapBigToHostInt32(superblob->length);
    uint32_t count      = OSSwapBigToHostInt32(superblob->count);
 
    size_t index_bytes = (size_t)count * sizeof(CS_BlobIndex);
    if (super_len < sizeof(CS_SuperBlob) || index_bytes > super_len - sizeof(CS_SuperBlob)) {
        return -1;
    }
 
    for (uint32_t i = 0; i < count; i++) {
        uint32_t type      = OSSwapBigToHostInt32(superblob->index[i].type);
        uint32_t cd_offset = OSSwapBigToHostInt32(superblob->index[i].offset);
 
        if (type != CSSLOT_CODEDIRECTORY) {
            continue;
        }
        if (cd_offset > super_len || super_len - cd_offset < sizeof(CS_CodeDirectory)) {
            return -1;
        }
 
        const CS_CodeDirectory *cd = (const CS_CodeDirectory *)(base + cd_offset);
        if (OSSwapBigToHostInt32(cd->magic) != CSMAGIC_CODEDIRECTORY) {
            return -1;
        }
 
        *cdflagsOffOut = (off_t)cd_offset + (off_t)offsetof(CS_CodeDirectory, flags);
        return 0;
    }
 
    return -1;
}

int HOOK(__fcntl)(int fd, int cmd, void *arg1, void *arg2, void *arg3, void *arg4, void *arg5, void *arg6, void *arg7, void *arg8)
{
	// Disable LV bypass if this process does not have a bootstrap port
	// But only if the process is also running in safe mode

	// We do not want to apply the LV bypass if injection into this process is disabled and it doesn't have a bootstrap port
	// This fixes the following things
	// - Driverkit processes crash looping
	//   (They will crash when trying to contact launchdhook over the port obtained from mach_ports_lookup)
	// - The system deadlocking during early boot

	if (jbinfo_is_checked_in() || proc_has_bootstrap_port()) {
		switch (cmd) {
			case F_ADDSIGS:
			case F_ADDFILESIGS:
			case F_ADDFILESIGS_RETURN: {
				struct siginfo siginfo;
				siginfo.source = (cmd == F_ADDSIGS) ? SIGNATURE_SOURCE_PROC : SIGNATURE_SOURCE_FILE;
				if (arg1) {
					memcpy(&siginfo.signature, (fsignatures_t *)arg1, sizeof (fsignatures_t));

					if (jbinfo_should_force_cs_adhoc()) {
						// Do whatever is neccessary to support non CS_ADHOC signed libraries on TXM devices
						// This isn't pretty, but it has to be done

						bool isFinished = false;
						int r = 0;

						bool isFile = (cmd == F_ADDFILESIGS || cmd == F_ADDFILESIGS_RETURN);
						bool superblobNeedsFree = false;

						CS_SuperBlob *superblob = NULL;
						if (isFile) {
							off_t orgPos = lseek(fd, 0, SEEK_CUR);
							superblob = load_signature(fd, &siginfo.signature);
							lseek(fd, orgPos, SEEK_SET);
							superblobNeedsFree = true;
						}
						else {
							superblob = (CS_SuperBlob *)siginfo.signature.fs_blob_start;
							if (siginfo.signature.fs_blob_size != OSSwapBigToHostInt32(superblob->length)) {
								superblob = NULL;
							}
						}

						if (superblob) {
							off_t cdFlagsOffset = 0;
							if (superblob_find_cdflags(superblob, &cdFlagsOffset) == 0) {
								uint32_t *cdFlagsPtr = (uint32_t *)((uintptr_t)superblob + cdFlagsOffset);
								if (!(OSSwapBigToHostInt32(*cdFlagsPtr) & CS_ADHOC)) {
									if (!isFile) {
										// If coming from F_ADDSIGS, it could be that the signature is mapped read-only
										// To ensure it is read write (so we can add CS_ADHOC), we need to copy it
										vm_address_t addr = 0;
										if (vm_allocate(mach_task_self(), &addr, OSSwapBigToHostInt32(superblob->length), VM_FLAGS_ANYWHERE) == 0) {
											memcpy((void *)addr, superblob, OSSwapBigToHostInt32(superblob->length));
											superblob = (CS_SuperBlob *)addr;
											superblobNeedsFree = true;
										}
									}

									if (superblobNeedsFree) {
										// If we don't have a copy of the superblob at this point, all bets are off

										cdFlagsPtr = (uint32_t *)((uintptr_t)superblob + cdFlagsOffset);
										*cdFlagsPtr |= OSSwapHostToBigInt32(CS_ADHOC);

										siginfo.source = SIGNATURE_SOURCE_PROC;
										siginfo.signature.fs_blob_start = (void *)superblob;

										// Get everything done here: Trust modified signature and attach it
										r = jbclient_mach_trust_file(fd, &siginfo);
										r = (int)msyscall_errno(0x5C, fd, F_ADDSIGS, &siginfo.signature, 0, 0, 0, 0, 0);
										isFinished = true;
									}
								}
							}

							if (superblobNeedsFree) {
								vm_deallocate(mach_task_self(), (vm_address_t)superblob, OSSwapBigToHostInt32(superblob->length));
							}
						}

						if (isFinished) {
							return r;
						}
					}
				}

				jbclient_mach_trust_file(fd, arg1 ? &siginfo : NULL);
				break;
			}
		}
	}

	return (int)msyscall_errno(0x5C, fd, cmd, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8);
}