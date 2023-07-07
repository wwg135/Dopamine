#import <spawn.h>
#import <libjailbreak/log.h>
#import "../systemhook/src/common.h"
#import "boomerang.h"
#import "substrate.h"
#import <mach-o/dyld.h>
#import <Foundation/Foundation.h>

void *posix_spawn_orig;
int posix_spawn_hook(pid_t *restrict pidp, const char *restrict path,
					   const posix_spawn_file_actions_t *restrict file_actions,
					   const posix_spawnattr_t *restrict attrp,
					   char *const argv[restrict],
					   char *const envp[restrict])
{
	if (path) {
		const char *firstArg = "<none>";
		if (argv[0]) {
			if (argv[1]) {
				firstArg = argv[1];
			}
		}

		char executablePath[1024];
		uint32_t bufsize = sizeof(executablePath);
		_NSGetExecutablePath(&executablePath[0], &bufsize);
		if (!strcmp(path, executablePath)) {
			// This spawn will perform a userspace reboot...
			// Instead of the ordinary hook, we want to reinsert this dylib
			// This has already been done in envp so we only need to call the regular posix_spawn

			// But before, we want to pass the primitives to boomerang
			boomerang_userspaceRebootIncoming();

			//FILE *f = fopen("/var/mobile/launch_log.txt", "a");
			//fprintf(f, "==== USERSPACE REBOOT ====\n");
			//fclose(f);

			// Say goodbye to this process
			int (*orig)(pid_t *restrict, const char *restrict, const posix_spawn_file_actions_t *restrict, const posix_spawnattr_t *restrict, char *const[restrict], char *const[restrict]) = posix_spawn_orig;
			return orig(pidp, path, file_actions, attrp, argv, envp);
		}
	}

	/*if (path) {
		const char *firstArg = "<none>";
		if (argv[0]) {
			if (argv[1]) {
				firstArg = argv[1];
			}
		}
		FILE *f = fopen("/var/mobile/launch_log.txt", "a");
		fprintf(f, "posix_spawn %s %s\n", path, firstArg);
		fclose(f);

		if (!strcmp(path, "/usr/libexec/xpcproxy")) {
			const char *tmpBlacklist[] = {
				"com.apple.logd"
			};
			size_t blacklistCount = sizeof(tmpBlacklist) / sizeof(tmpBlacklist[0]);
			for (size_t i = 0; i < blacklistCount; i++)
			{
				if (!strcmp(tmpBlacklist[i], firstArg)) {
					FILE *f = fopen("/var/mobile/launch_log.txt", "a");
					fprintf(f, "blocked injection %s\n", firstArg);
					fclose(f);
					int (*orig)(pid_t *restrict, const char *restrict, const posix_spawn_file_actions_t *restrict, const posix_spawnattr_t *restrict, char *const[restrict], char *const[restrict]) = posix_spawn_orig;
					return orig(pid, path, file_actions, attrp, argv, envp);
				}
			}
		}
	}*/


	if (strcmp(path, "/usr/libexec/xpcproxy")==0 && access("/var/containers/Bundle/xpcproxy", F_OK)==0) {
		if(argv[0] && argv[1]) {

			if(
			 strstr(argv[1], "jailbreakd")==NULL

			&& strstr(argv[1], ".apple.")==NULL
			&& strstr(argv[1], "/Applications/")!=argv[1]
			&& strstr(argv[1], "/Developer/")!=argv[1]
			&& strstr(argv[1], "/System/")!=argv[1]
			&& strstr(argv[1], "/Library/")!=argv[1]
			&& strstr(argv[1], "/usr/")!=argv[1]
			&& strstr(argv[1], "/bin/")!=argv[1]
			&& strstr(argv[1], "/sbin/")!=argv[1]
			&& strstr(argv[1], "/private/preboot/")!=argv[1]
			&& strstr(argv[1], "/var/containers/Bundle/Application/")!=argv[1]
			&& strstr(argv[1], "/private/var/containers/Bundle/Application/")!=argv[1]

			
			)
			{
				JBLogDebug("use patched xpcproxy: %s", argv[1]);
				path = "/var/containers/Bundle/xpcproxy";
			}
		}
	}

	posix_spawnattr_t attr;
	if(!attrp) {
		attrp = &attr;
		posix_spawnattr_init(&attr);
	}

	short flags = 0;
    posix_spawnattr_getflags(attrp, &flags);

	int pid=0;
	int ret = spawn_hook_common(&pid, path, file_actions, attrp, argv, envp, posix_spawn_orig);
	if(pidp) *pidp=pid;

	JBLogDebug("launchd spawn ret=%d pid=%d path=%s flags=%x", ret, pid, path, flags);
	if(argv) for(int i=0; argv[i]; i++) JBLogDebug("\targs[%d] = %s", i, argv[i]);
	if(envp) for(int i=0; envp[i]; i++) JBLogDebug("\tenvp[%d] = %s", i, envp[i]);

	return ret;
}

void initSpawnHooks(void)
{
	MSHookFunction(&posix_spawn, (void *)posix_spawn_hook, &posix_spawn_orig);
}