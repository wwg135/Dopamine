#include <stdio.h>
#include <dlfcn.h>
#include <mach/mach.h>
#include <mach-o/dyld.h>
#include <mach-o/getsect.h>
#include <libjailbreak/dyld.h>
#include <libjailbreak/jbclient_xpc.h>
#include "common.h"
#include <os/log.h>

static kern_return_t (*EKHookMemoryRaw_orig)(void *target, const void *data, size_t size);
static kern_return_t EKHookMemoryRaw_impl(void *target, const void *data, size_t size)
{
	static uint64_t dscSlide = 0;
	static dispatch_once_t ot;
	dispatch_once(&ot, ^{
		task_dyld_info_data_t dyldInfo;
		uint32_t count = TASK_DYLD_INFO_COUNT;
		task_info(mach_task_self_, TASK_DYLD_INFO, (task_info_t)&dyldInfo, &count);
		DyldAllImageInfos64 *infos = (DyldAllImageInfos64 *)dyldInfo.all_image_info_addr;
		dscSlide = infos->shared_cache_slide;
	});

	Dl_info targetInfo;
	if (dladdr(target, &targetInfo) != 0) {
		if (_dyld_shared_cache_contains_path(targetInfo.dli_fname)) {
			uint64_t unslidTarget = (uint64_t)target - dscSlide;
			jbclient_mlock_dsc(unslidTarget, size);
		}
	}

	return EKHookMemoryRaw_orig(target, data, size);
}

static bool ignore_images = true;
static void image_added(const struct mach_header *mh, intptr_t vmaddr_slide)
{
	if (ignore_images) return;

	Dl_info info;
	if (dladdr(mh, &info) != 0) {
		if (stringEndsWith(info.dli_fname, "/usr/lib/libellekit.dylib")) {
			void *handle = dlopen(info.dli_fname, RTLD_NOLOAD);
			kern_return_t (**EKHookMemoryRaw)(void *, const void *, size_t) = dlsym(handle, "EKHookMemoryRaw");
			if (EKHookMemoryRaw) {
				EKHookMemoryRaw_orig = *EKHookMemoryRaw;
				*EKHookMemoryRaw = EKHookMemoryRaw_impl;
			}
			ignore_images = true;
		}
	}
}

void enable_ellekit_custom_memory_hooks(void)
{
	_dyld_register_func_for_add_image(image_added);
	ignore_images = false;
}