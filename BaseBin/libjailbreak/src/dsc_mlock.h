#include <choma/DyldSharedCache.h>

int dsc_mlock_unslid(uint64_t unslid_addr, size_t size);
int dsc_mlock(void *addr, size_t size);
int dsc_mlock_library_exec(const char *name);