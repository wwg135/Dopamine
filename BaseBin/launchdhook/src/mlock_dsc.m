#import <Foundation/Foundation.h>
#import <dlfcn.h>
#import <libjailbreak/libjailbreak.h>
#import <sys/param.h>
#import <sys/mount.h>
#import <objc/runtime.h>
#import <sys/mman.h>
#import <libjailbreak/dyld.h>

struct dsc_text_segment {
	void *mapping;
	uint64_t offset;
	uint64_t address;
	uint64_t size;
};

int mlock_dsc(uint64_t unslid_addr, size_t size)
{
	static struct dsc_text_segment *segments = NULL;
	static int segmentCount = 0;
	static dispatch_once_t ot;
	dispatch_once(&ot, ^{
		NSURL *dscURL = [NSURL fileURLWithPath:@"/System/Library/Caches/com.apple.dyld" isDirectory:YES];
		for (NSURL *partURL in [[NSFileManager defaultManager] contentsOfDirectoryAtURL:dscURL includingPropertiesForKeys:nil options:0 error:nil]) {
			if (![partURL.pathExtension isEqualToString:@"symbols"]) {
				FILE *f = fopen(partURL.fileSystemRepresentation, "r");
				if (f) {
					fseek(f, 0, SEEK_SET);
					struct dyld_cache_header header = { 0 };
					if (fread(&header, sizeof(header), 1, f) == 1) {
						for (uint32_t i = 0; i < header.mappingCount; i++) {
							uint32_t curMappingOff = header.mappingOffset + (i * sizeof(struct dyld_cache_mapping_info));
							fseek(f, curMappingOff, SEEK_SET);
							struct dyld_cache_mapping_info curMapping = { 0 };
							if (fread(&curMapping, sizeof(curMapping), 1, f) == 1) {
								if (curMapping.initProt & PROT_EXEC) {
									void *textMap = mmap(NULL, curMapping.size, PROT_READ, MAP_SHARED, fileno(f), curMapping.fileOffset);
									if (textMap != MAP_FAILED) {
										segmentCount++;
										segments = realloc(segments, segmentCount * sizeof(struct dsc_text_segment));
										segments[segmentCount-1] = (struct dsc_text_segment){
											.mapping = textMap,
											.offset = curMapping.fileOffset,
											.address = curMapping.address,
											.size = curMapping.size,
										};
									}
								}
							}
						}
					}
					fclose(f);
				}
			}
		}
	});

	for (int i = 0; i < segmentCount; i++) {
		struct dsc_text_segment *curSegment = &segments[i];
		if (unslid_addr >= curSegment->address && (unslid_addr + size) < (curSegment->address + curSegment->size)) {
			uint64_t rel = unslid_addr - curSegment->address;
			void *start = (void *)((uint64_t)curSegment->mapping + rel);
			int r = mlock(start, size);
			FILE *f = fopen("/var/mobile/launchd_dsc_lock.log", "a");
			fprintf(f, "mlock(unslid_addr: 0x%llx, addr: %p, size: 0x%zx) => %d\n", unslid_addr, start, size, r);
			fclose(f);
			return r;
		}
	}

	return -1;
}