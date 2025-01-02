#include "oldabi.h"
#include <libjailbreak/dsc_mlock.h>
#include <libjailbreak/util.h>
#include <libjailbreak/primitives.h>
#include <mach-o/getsect.h>

int oldabi_patch_library(const char *name, void **backupdata, size_t *backupsize)
{
	const struct mach_header *mh = get_mach_header(name);
	if (!mh) return -1;

	unsigned long sectionSize = 0;
	uint32_t *instructions = (uint32_t *)getsectiondata((const struct mach_header_64 *)mh, "__TEXT", "__text", &sectionSize);

	if (backupdata) {
		*backupsize = sectionSize;
		*backupdata = malloc(sectionSize);
		memcpy(*backupdata, instructions, sectionSize);
	}

	dsc_mlock(instructions, sectionSize);

	for (int i = 0; i < (sectionSize / sizeof(uint32_t)); i++) {
		if ((instructions[i] & 0xfffffc00) == 0xdac11800) {
			uint32_t replacement = 0xdac147f0;
			vwritebuf(ttep_self(), &instructions[i], &replacement, sizeof(replacement));
		}
	}
	return 0;
}

int oldabi_revert_library(const char *name, void *backupdata, size_t backupsize)
{
	const struct mach_header *mh = get_mach_header(name);
	if (!mh) return -1;

	unsigned long sectionSize = 0;
	uint32_t *instructions = (uint32_t *)getsectiondata((const struct mach_header_64 *)mh, "__TEXT", "__text", &sectionSize);
	vwritebuf(ttep_self(), instructions, backupdata, backupsize);
	return 0;
}

#ifdef __arm64e__

void *gObjcBackup = NULL, *gCfBackup = NULL;
size_t gObjcBackupSize = 0, gCfBackupSize = 0;
bool gOldAbiSupportEnabled = false;
int jb_set_oldabi_support_enabled(bool enabled)
{
	if (enabled != gOldAbiSupportEnabled) {
		gOldAbiSupportEnabled = enabled;
		if (enabled) {
			if (!gObjcBackup) {
				oldabi_patch_library("/usr/lib/libobjc.A.dylib", &gObjcBackup, &gObjcBackupSize);
			}
			if (!gCfBackup) {
				oldabi_patch_library("/System/Library/Frameworks/CoreFoundation.framework/CoreFoundation", &gCfBackup, &gCfBackupSize);
			}
		}
		else {
			if (gObjcBackup) {
				oldabi_revert_library("/usr/lib/libobjc.A.dylib", gObjcBackup, gObjcBackupSize);
				free(gObjcBackup);
				gObjcBackup = NULL;
			}
			if (gCfBackup) {
				oldabi_revert_library("/System/Library/Frameworks/CoreFoundation.framework/CoreFoundation", gCfBackup, gCfBackupSize);
				free(gCfBackup);
				gCfBackup = NULL;
			}
		}
	}
	return 0;
}

bool jb_is_oldabi_fix_enabled(void)
{
	return gOldAbiSupportEnabled;
}

#else

int jb_set_oldabi_support_enabled(bool enabled)
{
	return -1;
}

bool jb_is_oldabi_fix_enabled(void)
{
	return false;
}

#endif