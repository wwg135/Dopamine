#include "dsc_mlock.h"
#include <mach-o/dyld_images.h>
#include <sys/mman.h>
#include <dispatch/dispatch.h>
#include <choma/MachO.h>
#include <litehook.h>

DyldSharedCache *_get_live_dsc(void)
{
	static DyldSharedCache *liveDSC = NULL;
	static dispatch_once_t ot;
	dispatch_once(&ot, ^{
		liveDSC = dsc_init_from_path(litehook_locate_dsc());
	});
	return liveDSC;
}

int dsc_mlock_unslid(uint64_t unslid_addr, size_t size)
{
	void *ptr = dsc_find_buffer(_get_live_dsc(), unslid_addr, size);
	if (!ptr) return -1;
	return mlock(ptr, size);
}

int dsc_mlock(void *addr, size_t size)
{
	static uint64_t dscSlide = 0;
	static dispatch_once_t ot;
	dispatch_once(&ot, ^{
		task_dyld_info_data_t dyldInfo;
		uint32_t count = TASK_DYLD_INFO_COUNT;
		task_info(mach_task_self_, TASK_DYLD_INFO, (task_info_t)&dyldInfo, &count);
		struct dyld_all_image_infos *infos = (struct dyld_all_image_infos *)dyldInfo.all_image_info_addr;
		dscSlide = infos->sharedCacheSlide;
	});
	return dsc_mlock_unslid((uint64_t)addr - dscSlide, size);
}

int dsc_mlock_library_exec(const char *name)
{
	MachO *macho = dsc_lookup_macho_by_path(_get_live_dsc(), name, NULL);
	if (!macho) return -1;

	__block int r = 0;
	macho_enumerate_segments(macho, ^(struct segment_command_64 *segment, bool *stop) {
		if (segment->initprot & PROT_EXEC) {
			r = dsc_mlock_unslid(segment->vmaddr, segment->vmsize);
			if (r != 0) *stop = true;
		}
	});
	return r;
}