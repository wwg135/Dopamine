struct dyld_cache_header
{
	char        magic[16];              // e.g. "dyld_v0    i386"
	uint32_t    mappingOffset;          // file offset to first dyld_cache_mapping_info
	uint32_t    mappingCount;           // number of dyld_cache_mapping_info entries
	uint32_t    imagesOffset;           // file offset to first dyld_cache_image_info
	uint32_t    imagesCount;            // number of dyld_cache_image_info entries
	uint64_t    dyldBaseAddress;        // base address of dyld when cache was built
	uint64_t    codeSignatureOffset;    // file offset of code signature blob
	uint64_t    codeSignatureSize;      // size of code signature blob (zero means to end of file)
	uint64_t    slideInfoOffsetUnused;  // unused.  Used to be file offset of kernel slid info
	uint64_t    slideInfoSizeUnused;    // unused.  Used to be size of kernel slid info
	uint64_t    localSymbolsOffset;     // file offset of where local symbols are stored
	uint64_t    localSymbolsSize;       // size of local symbols information
	uint8_t     uuid[16];               // unique value for each shared cache file
	uint64_t    cacheType;              // 0 for development, 1 for production
	uint32_t    branchPoolsOffset;      // file offset to table of uint64_t pool addresses
	uint32_t    branchPoolsCount;       // number of uint64_t entries
	uint64_t    accelerateInfoAddr;     // (unslid) address of optimization info
	uint64_t    accelerateInfoSize;     // size of optimization info
	uint64_t    imagesTextOffset;       // file offset to first dyld_cache_image_text_info
	uint64_t    imagesTextCount;        // number of dyld_cache_image_text_info entries
	uint64_t    patchInfoAddr;          // (unslid) address of dyld_cache_patch_info
	uint64_t    patchInfoSize;          // Size of all of the patch information pointed to via the dyld_cache_patch_info
	uint64_t    otherImageGroupAddrUnused;    // unused
	uint64_t    otherImageGroupSizeUnused;    // unused
	uint64_t    progClosuresAddr;       // (unslid) address of list of program launch closures
	uint64_t    progClosuresSize;       // size of list of program launch closures
	uint64_t    progClosuresTrieAddr;   // (unslid) address of trie of indexes into program launch closures
	uint64_t    progClosuresTrieSize;   // size of trie of indexes into program launch closures
	uint32_t    platform;               // platform number (macOS=1, etc)
	uint32_t    formatVersion          : 8,  // dyld3::closure::kFormatVersion
							dylibsExpectedOnDisk   : 1,  // dyld should expect the dylib exists on disk and to compare inode/mtime to see if cache is valid
							simulator              : 1,  // for simulator of specified platform
							locallyBuiltCache      : 1,  // 0 for B&I built cache, 1 for locally built cache
							builtFromChainedFixups : 1,  // some dylib in cache was built using chained fixups, so patch tables must be used for overrides
							padding                : 20; // TBD
	uint64_t    sharedRegionStart;      // base load address of cache if not slid
	uint64_t    sharedRegionSize;       // overall size of region cache can be mapped into
	uint64_t    maxSlide;               // runtime slide of cache can be between zero and this value
	uint64_t    dylibsImageArrayAddr;   // (unslid) address of ImageArray for dylibs in this cache
	uint64_t    dylibsImageArraySize;   // size of ImageArray for dylibs in this cache
	uint64_t    dylibsTrieAddr;         // (unslid) address of trie of indexes of all cached dylibs
	uint64_t    dylibsTrieSize;         // size of trie of cached dylib paths
	uint64_t    otherImageArrayAddr;    // (unslid) address of ImageArray for dylibs and bundles with dlopen closures
	uint64_t    otherImageArraySize;    // size of ImageArray for dylibs and bundles with dlopen closures
	uint64_t    otherTrieAddr;          // (unslid) address of trie of indexes of all dylibs and bundles with dlopen closures
	uint64_t    otherTrieSize;          // size of trie of dylibs and bundles with dlopen closures
	uint32_t    mappingWithSlideOffset; // file offset to first dyld_cache_mapping_and_slide_info
	uint32_t    mappingWithSlideCount;  // number of dyld_cache_mapping_and_slide_info entries
};

struct dyld_cache_mapping_info {
	uint64_t    address;
	uint64_t    size;
	uint64_t    fileOffset;
	uint32_t    maxProt;
	uint32_t    initProt;
};

struct _DyldAllImageInfos64
{
	uint32_t version;
	uint32_t info_array_count;
	uint64_t info_array;
	uint64_t notification;
	uint8_t process_detached_from_shared_region;
	uint8_t libsystem_initialized;
	uint32_t padding;
	uint64_t dyld_image_load_address;
	uint64_t jit_info;
	uint64_t dyld_version;
	uint64_t error_message;
	uint64_t termination_flags;
	uint64_t core_symbolication_shm_page;
	uint64_t system_order_flag;
	uint64_t uuid_array_count;
	uint64_t uuid_array;
	uint64_t dyld_all_image_infos_address;
	uint64_t initial_image_count;
	uint64_t error_kind;
	uint64_t error_client_of_dylib_path;
	uint64_t error_target_dylib_path;
	uint64_t error_symbol;
	uint64_t shared_cache_slide;
	uint8_t shared_cache_uuid[16];
	uint64_t shared_cache_base_address;
	volatile uint64_t info_array_change_timestamp;
	uint64_t dyld_path;
	uint32_t notify_mach_ports[8];
	uint64_t reserved[9];
	uint64_t compact_dyld_image_info_addr;
	uint64_t compact_dyld_image_info_size;
	uint32_t platform;
};
typedef struct _DyldAllImageInfos64 DyldAllImageInfos64;
