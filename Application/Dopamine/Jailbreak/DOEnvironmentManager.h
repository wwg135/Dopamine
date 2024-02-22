//
//  EnvironmentManager.h
//  Dopamine
//
//  Created by Lars Fröder on 10.01.24.
//

#import <Foundation/Foundation.h>
#import "DOBootstrapper.h"

NS_ASSUME_NONNULL_BEGIN

@interface DOEnvironmentManager : NSObject
{
    DOBootstrapper *_bootstrapper;
    BOOL _bootstrapNeedsMigration;
}

+ (instancetype)sharedManager;

@property (nonatomic, readonly) NSData *bootManifestHash;

- (BOOL)isInstalledThroughTrollStore;
- (BOOL)isJailbroken;
- (BOOL)isBootstrapped;
- (NSString *)jailbrokenVersion;

- (BOOL)isSupported;
- (BOOL)isArm64e;
- (NSString *)versionSupportString;
- (NSString *)accessibleKernelPath;
- (void)locateJailbreakRoot;
- (void)ensureJailbreakRootExists;


- (void)runUnsandboxed:(void (^)(void))unsandboxBlock;
- (void)runAsRoot:(void (^)(void))rootBlock;

- (void)respring;
- (void)rebootUserspace;
- (void)refreshJailbreakApps;
- (void)reboot;
- (NSError*)updateEnvironment;
- (void)updateJailbreakFromTIPA:(NSString *)tipaPath;

- (BOOL)isTweakInjectionEnabled;
- (void)setTweakInjectionEnabled:(BOOL)enabled;
- (BOOL)isIDownloadEnabled;
- (void)setIDownloadEnabled:(BOOL)enabled;
- (BOOL)checkforupdatesEnabled;
- (void)setCheckforupdatesEnabled:(BOOL)enabled;
- (BOOL)newfunctionEnabled;
- (void)setNewfunctionEnabled:(BOOL)enabled;
- (BOOL)isJailbreakHidden;
- (void)setJailbreakHidden:(BOOL)hidden;

- (BOOL)isPACBypassRequired;
- (BOOL)isPPLBypassRequired;

- (NSError *)prepareBootstrap;
- (NSError *)finalizeBootstrap;
- (NSError *)deleteBootstrap;
- (NSError *)reinstallPackageManagers;
@end

NS_ASSUME_NONNULL_END
