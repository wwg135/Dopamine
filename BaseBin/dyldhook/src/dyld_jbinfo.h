#define DYLD_JBINFO_MAXSIZE 0x3f00

// A struct that allows dyldhook to stash information that systemhook can later access
struct dyld_jbinfo {
	char *sandboxExtensions;
	char *bootUUID;
	char *jbRootPath;
	bool fullyDebugged;

	char data[];
};