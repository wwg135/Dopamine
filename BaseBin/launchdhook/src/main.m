#import <Foundation/Foundation.h>
#import <libjailbreak/libjailbreak.h>
#import <libjailbreak/handoff.h>
#import <libjailbreak/kcall.h>
#import <libjailbreak/launchd.h>
#import <libfilecom/FCHandler.h>
#import <mach-o/dyld.h>
#import <spawn.h>

#import <sandbox.h>
#import "spawn_hook.h"
#import "xpc_hook.h"
#import "daemon_hook.h"
#import "ipc_hook.h"
#import "crashreporter.h"
#import "../systemhook/src/common.h"

int gLaunchdImageIndex = -1;

NSString *generateSystemWideSandboxExtensions(void)
{
	NSMutableString *extensionString = [NSMutableString new];


	[extensionString appendString:[NSString stringWithUTF8String:sandbox_extension_issue_file("com.apple.app-sandbox.read", "/var/jbroot", 0)]];
	[extensionString appendString:@"|"];
	[extensionString appendString:[NSString stringWithUTF8String:sandbox_extension_issue_file("com.apple.sandbox.executable", "/var/jbroot", 0)]];
	[extensionString appendString:@"|"];


	[extensionString appendString:[NSString stringWithUTF8String:sandbox_extension_issue_file("com.apple.app-sandbox.read", "/var/containers/Bundle/jbroot", 0)]];
	[extensionString appendString:@"|"];
	[extensionString appendString:[NSString stringWithUTF8String:sandbox_extension_issue_file("com.apple.sandbox.executable", "/var/containers/Bundle/jbroot", 0)]];
	[extensionString appendString:@"|"];



	// Make /var/jb readable
	[extensionString appendString:[NSString stringWithUTF8String:sandbox_extension_issue_file("com.apple.app-sandbox.read", jbrootPath(@"/").fileSystemRepresentation, 0)]];
	[extensionString appendString:@"|"];

	// Make binaries in /var/jb executable
	[extensionString appendString:[NSString stringWithUTF8String:sandbox_extension_issue_file("com.apple.sandbox.executable", jbrootPath(@"/").fileSystemRepresentation, 0)]];
	[extensionString appendString:@"|"];

	// Ensure the whole system has access to com.opa334.jailbreakd.systemwide
	[extensionString appendString:[NSString stringWithUTF8String:sandbox_extension_issue_mach("com.apple.app-sandbox.mach", "com.opa334.jailbreakd.systemwide", 0)]];
	[extensionString appendString:@"|"];
	[extensionString appendString:[NSString stringWithUTF8String:sandbox_extension_issue_mach("com.apple.security.exception.mach-lookup.global-name", "com.opa334.jailbreakd.systemwide", 0)]];

	return extensionString;
}

__attribute__((constructor)) static void initializer(void)
{
	//crashreporter_start();
	bool comingFromUserspaceReboot = bootInfo_getUInt64(@"environmentInitialized");
	if (comingFromUserspaceReboot) {
		JBLogDebug("comingFromUserspaceReboot=1");

		// super hacky fix to support OTA updates from 1.0.x to 1.1
		// I hate it, but there is no better way :/
		NSURL *disabledLaunchDaemonURL = [NSURL fileURLWithPath:jbrootPath(@"/basebin/LaunchDaemons/Disabled") isDirectory:YES];
		NSArray<NSURL *> *disabledLaunchDaemonPlistURLs = [[NSFileManager defaultManager] contentsOfDirectoryAtURL:disabledLaunchDaemonURL includingPropertiesForKeys:nil options:0 error:nil];
		for (NSURL *disabledLaunchDaemonPlistURL in disabledLaunchDaemonPlistURLs) {
			patchBaseBinLaunchDaemonPlist(disabledLaunchDaemonPlistURL.path);
		}

		// Launchd was already initialized before, we are coming from a userspace reboot... recover primitives
		// First get PPLRW primitives
		__block pid_t boomerangPid = 0;
		dispatch_semaphore_t sema = dispatch_semaphore_create(0);
		FCHandler *handler = [[FCHandler alloc] initWithReceiveFilePath:jbrootPath(@"/var/.communication/boomerang_to_launchd") sendFilePath:jbrootPath(@"/var/.communication/launchd_to_boomerang")];
		handler.receiveHandler = ^(NSDictionary *message) {
			JBLogDebug("receiveHandler: message=%p", message);
			NSString *identifier = message[@"id"];
			if (identifier) {
				JBLogDebug("receiveHandler: identifier=%s", identifier.UTF8String);
				if ([identifier isEqualToString:@"receivePPLRW"])
				{
					uint64_t magicPage = [(NSNumber*)message[@"magicPage"] unsignedLongLongValue];
					boomerangPid = [(NSNumber*)message[@"boomerangPid"] intValue];
					JBLogDebug("receiveHandler: magicPage=%llx, boomerangPid=%d", magicPage, boomerangPid);
					initPPLPrimitives(magicPage);
					dispatch_semaphore_signal(sema);
				}
			}
		};
		[handler sendMessage:@{ @"id" : @"getPPLRW" }];
		dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
		int ret = recoverPACPrimitives();
		JBLogDebug("recoverPACPrimitives=%d", ret);
		[handler sendMessage:@{ @"id" : @"primitivesInitialized" }];
		[[NSFileManager defaultManager] removeItemAtPath:jbrootPath(@"/var/.communication") error:nil];
		if (boomerangPid != 0) {
			int status;
			waitpid(boomerangPid, &status, WEXITED);
			waitpid(boomerangPid, &status, 0);
		}
		bootInfo_setObject(@"jbdIconCacheNeedsRefresh", @1);
	}
	else {
		// Launchd hook loaded for first time, get primitives from jailbreakd
		int ret = jbdInitPPLRW();
		JBLogDebug("jbdInitPPLRW=%d", ret);
		int ret2 = recoverPACPrimitives();
		JBLogDebug("jbdInitPPLRW=%d", ret2);
	}

	for (int i = 0; i < _dyld_image_count(); i++) {
		if(!strcmp(_dyld_get_image_name(i), "/sbin/launchd")) {
			gLaunchdImageIndex = i;
			break;
		}
	}

	// System wide sandbox extensions and root path
	setenv("JB_SANDBOX_EXTENSIONS", generateSystemWideSandboxExtensions().UTF8String, 1);
	setenv("JB_ROOT_PATH", jbrootPath(@"/").fileSystemRepresentation, 1);
	JB_SandboxExtensions = strdup(getenv("JB_SANDBOX_EXTENSIONS"));
	JB_RootPath = strdup(getenv("JB_ROOT_PATH"));

	JBRAND = strdup(((NSString*)bootInfo_getObject(@"JBRAND")).UTF8String);
	JBROOT = strdup(((NSString*)bootInfo_getObject(@"JBROOT")).UTF8String);

	proc_set_debugged_pid(getpid(), false);
	initXPCHooks();
	initDaemonHooks();
	initSpawnHooks();
	initIPCHooks();

	// This will ensure launchdhook is always reinjected after userspace reboots
	// As this launchd will pass environ to the next launchd...
	setenv("DYLD_INSERT_LIBRARIES", jbrootPath(@"/basebin/launchdhook.dylib").fileSystemRepresentation, 1);

	bootInfo_setObject(@"environmentInitialized", @1);
}