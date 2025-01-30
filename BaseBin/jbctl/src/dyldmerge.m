#import <libjailbreak/libjailbreak.h>
#import <sys/sysctl.h>

NSString *dyldhook_dylib_for_platform(void)
{
	cpu_subtype_t cpusubtype = 0;
	size_t len = sizeof(cpusubtype);
	if (sysctlbyname("hw.cpusubtype", &cpusubtype, &len, NULL, 0) == -1) { return nil; }
	if ((cpusubtype & ~CPU_SUBTYPE_MASK) == CPU_SUBTYPE_ARM64E) {
		if (@available(iOS 16.0, *)) {
			return @"dyldhook_merge.arm64e.dylib"; 
		}
		else {
			return @"dyldhook_merge.arm64e.iOS15.dylib"; 
		}
	}
	else {
		if (@available(iOS 16.0, *)) {
			return @"dyldhook_merge.arm64.dylib"; 
		}
		else {
			return @"dyldhook_merge.arm64.iOS15.dylib"; 
		}
	}
}

int merge_dyldhook(NSString *originalDyldPath, NSString *basebinPath, NSString *outPath)
{
	NSString *dyldhookMergeDylibName = dyldhook_dylib_for_platform();
	if (!dyldhookMergeDylibName) {
		printf("FATAL ERROR: Unable to locate dyldhook.dylib\n");
		return -1;
	}
	NSString *dyldhookMergeDylibPath = [basebinPath stringByAppendingPathComponent:dyldhookMergeDylibName];
	NSString *machoMergerPath = [basebinPath stringByAppendingPathComponent:@"MachOMerger"];

	int r = exec_cmd(machoMergerPath.fileSystemRepresentation, originalDyldPath.fileSystemRepresentation, dyldhookMergeDylibPath.fileSystemRepresentation, outPath.fileSystemRepresentation, NULL);
	if (r == 0) {
		r = chmod(outPath.fileSystemRepresentation, 0755);
	}
	return r;
}