#import <Foundation/Foundation.h>
#import <libjailbreak/libjailbreak.h>
#import <libjailbreak/signatures.h>
#import <sandbox.h>
#import "dyld_patch.h"
#import "trustcache.h"
#import <sys/param.h>
#import <sys/mount.h>
#import <copyfile.h>

extern void setJetsamEnabled(bool enabled);

NSArray *writableFileAttributes(void)
{
	static NSArray *attributes = nil;
	static dispatch_once_t onceToken;
	dispatch_once (&onceToken, ^{
		attributes = @[NSFileBusy, NSFileCreationDate, NSFileExtensionHidden, NSFileGroupOwnerAccountID, NSFileGroupOwnerAccountName, NSFileHFSCreatorCode, NSFileHFSTypeCode, NSFileImmutable, NSFileModificationDate, NSFileOwnerAccountID, NSFileOwnerAccountName, NSFilePosixPermissions];
	});
	return attributes;
}

NSDictionary *writableAttributes(NSDictionary *attributes)
{
	NSArray *writableAttributes = writableFileAttributes();
	NSMutableDictionary *newDict = [NSMutableDictionary new];

	[attributes enumerateKeysAndObjectsUsingBlock:^(NSString *attributeKey, NSObject *attribute, BOOL *stop) {
		if([writableAttributes containsObject:attributeKey]) {
			newDict[attributeKey] = attribute;
		}
	}];

	return newDict.copy;
}

bool fileExistsOrSymlink(NSString *path, BOOL *isDirectory)
{
	if ([[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:isDirectory]) return YES;
	if ([[NSFileManager defaultManager] attributesOfItemAtPath:path error:nil]) return YES;
	return NO;
}

int carbonCopySingle(NSString *sourcePath, NSString *targetPath)
{
	BOOL isDirectory = NO;
	BOOL exists = fileExistsOrSymlink(sourcePath, &isDirectory);
	if (!exists) {
		return 1;
	}

	if (fileExistsOrSymlink(targetPath, nil)) {
		[[NSFileManager defaultManager] removeItemAtPath:targetPath error:nil];
	}

	NSDictionary* attributes = writableAttributes([[NSFileManager defaultManager] attributesOfItemAtPath:sourcePath error:nil]);
	if (isDirectory) {
		return [[NSFileManager defaultManager] createDirectoryAtPath:targetPath withIntermediateDirectories:NO attributes:attributes error:nil] != YES;
	}
	else {
		if ([[NSFileManager defaultManager] copyItemAtPath:sourcePath toPath:targetPath error:nil]) {
			[[NSFileManager defaultManager] setAttributes:attributes ofItemAtPath:targetPath error:nil];
			return 0;
		}
		return 1;
	}
}

int carbonCopy(NSString *sourcePath, NSString *targetPath)
{
	setJetsamEnabled(NO);
	int retval = 0;
	BOOL isDirectory = NO;
	BOOL exists = fileExistsOrSymlink(sourcePath, &isDirectory);
	if (exists) {
		if (isDirectory) {
			retval = carbonCopySingle(sourcePath, targetPath);
			if (retval == 0) {
				NSDirectoryEnumerator *enumerator = [[NSFileManager defaultManager] enumeratorAtPath:sourcePath];
				for (NSString *relativePath in enumerator) {
					@autoreleasepool {
						NSString *subSourcePath = [sourcePath stringByAppendingPathComponent:relativePath];
						NSString *subTargetPath = [targetPath stringByAppendingPathComponent:relativePath];
						retval = carbonCopySingle(subSourcePath, subTargetPath);
						if (retval != 0) break;
					}
				}
			}

		}
		else {
			retval = carbonCopySingle(sourcePath, targetPath);
		}
	}
	else {
		retval = 1;
	}
	setJetsamEnabled(YES);
	return retval;
}

int setFakeLibVisible(bool visible)
{
	bool isCurrentlyVisible = [[NSFileManager defaultManager] fileExistsAtPath:jbrootPath(@"/basebin/.fakelib/systemhook.dylib")];
	if (isCurrentlyVisible != visible) {
		NSString *stockDyldPath = jbrootPath(@"/basebin/.dyld");
		NSString *patchedDyldPath = jbrootPath(@"/basebin/.dyld_patched");
		NSString *dyldFakeLibPath = jbrootPath(@"/basebin/.fakelib/dyld");

		NSString *systemhookPath = jbrootPath(@"/basebin/systemhook.dylib");
		NSString *systemhookFakeLibPath = jbrootPath(@"/basebin/.fakelib/systemhook.dylib");

		if (visible) {
			if (![[NSFileManager defaultManager] copyItemAtPath:systemhookPath toPath:systemhookFakeLibPath error:nil]) return 10;
			if (carbonCopy(patchedDyldPath, dyldFakeLibPath) != 0) return 11;
			JBLogDebug("Made fakelib visible");
		}
		else {
			if (![[NSFileManager defaultManager] removeItemAtPath:systemhookFakeLibPath error:nil]) return 12;
			if (carbonCopy(stockDyldPath, dyldFakeLibPath) != 0) return 13;
			JBLogDebug("Made fakelib not visible");
		}
	}
	return 0;
}

int makeFakeLib(void)
{
	NSString *libPath = @"/usr/lib";
	NSString *fakeLibPath = jbrootPath(@"/basebin/.fakelib");
	NSString *dyldBackupPath = jbrootPath(@"/basebin/.dyld");
	NSString *dyldToPatch = jbrootPath(@"/basebin/.dyld_patched");

	if (carbonCopy(libPath, fakeLibPath) != 0) return 1;
	JBLogDebug("copied %s to %s", libPath.UTF8String, fakeLibPath.UTF8String);

	if (carbonCopy(@"/usr/lib/dyld", dyldToPatch) != 0) return 2;
	JBLogDebug("created patched dyld at %s", dyldToPatch.UTF8String);

	if (carbonCopy(@"/usr/lib/dyld", dyldBackupPath) != 0) return 3;
	JBLogDebug("created stock dyld backup at %s", dyldBackupPath.UTF8String);

	int dyldRet = applyDyldPatches(dyldToPatch);
	if (dyldRet != 0) return dyldRet;
	JBLogDebug("patched dyld at %s", dyldToPatch.UTF8String);

	NSData *dyldCDHash;
	evaluateSignature([NSURL fileURLWithPath:dyldToPatch], &dyldCDHash, nil);
	if (!dyldCDHash) return 4;
	JBLogDebug("got dyld cd hash %s", dyldCDHash.description.UTF8String);

	size_t dyldTCSize = 0;
	uint64_t dyldTCKaddr = staticTrustCacheUploadCDHashesFromArray(@[dyldCDHash], &dyldTCSize);
	if(dyldTCSize == 0 || dyldTCKaddr == 0) return 5;
	bootInfo_setObject(@"dyld_trustcache_kaddr", @(dyldTCKaddr));
	bootInfo_setObject(@"dyld_trustcache_size", @(dyldTCSize));
	JBLogDebug("dyld trust cache inserted, allocated at %llX (size: %zX)", dyldTCKaddr, dyldTCSize);

	return setFakeLibVisible(true);
}

bool isFakeLibBindMountActive(void)
{
	struct statfs fs;
	int sfsret = statfs("/usr/lib", &fs);
	if (sfsret == 0) {
		return !strcmp(fs.f_mntonname, "/usr/lib");
	}
	return NO;
}

int setFakeLibBindMountActive(bool active)
{
	__block int ret = -1;
	bool alreadyActive = isFakeLibBindMountActive();
	if (active != alreadyActive) {
		if (active) {
			run_unsandboxed(^{
				ret = mount("bindfs", "/usr/lib", MNT_RDONLY, (void*)jbrootPath(@"/basebin/.fakelib").fileSystemRepresentation);
			});
		}
		else {
			run_unsandboxed(^{
				ret = unmount("/usr/lib", 0);
			});
		}
	}
	return ret;
}

int64_t registerJbPrefixedPath(NSString *sourcePath, int retry) {
  NSString *jbPrefixedPath = jbrootPath(sourcePath);

  NSFileManager *fm = [NSFileManager defaultManager];

  bool required_copy;
  if (![fm fileExistsAtPath:jbPrefixedPath]) {
    required_copy = true;
  } else {
    NSArray* list = [fm contentsOfDirectoryAtPath:jbPrefixedPath error:nil];
    if (list != nil && list.count == 0) {
      for (int i = 0; i != retry && ![fm removeItemAtPath:jbPrefixedPath error:nil]; ++i) {}
      required_copy = true;
    } else {
      required_copy = false;
    }
  }

  if (required_copy) {
    // 0x0. copy items to a tmpPath
    if (![fm fileExistsAtPath:sourcePath]) {
      return -1;
    }
    NSString* tmpPath = [NSString stringWithFormat:@"%@_tmp", jbPrefixedPath];
    for (int i = 0; i != retry &&
      ![fm createDirectoryAtPath:tmpPath withIntermediateDirectories:YES attributes:nil error:nil]; ++i) {}
    for (int i = 0; i != retry && ![fm removeItemAtPath:tmpPath error:nil]; ++i) {}
    for (int i = 0; i != retry && ![fm copyItemAtPath:sourcePath toPath:tmpPath error:nil]; ++i) {}

    // 0x1. mv items to the jbPrefixedPath
    for (int i = 0; i != retry && ![fm moveItemAtPath:tmpPath toPath:jbPrefixedPath error:nil]; ++i) {}
  }

  run_unsandboxed(^{
    mount("bindfs", sourcePath.fileSystemRepresentation, MNT_RDONLY, (void*)jbPrefixedPath.fileSystemRepresentation);
  });
  return 0;
}

int64_t bindMountPath(NSString *sourcePath, bool check_existances) {
  sourcePath = [sourcePath stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
  // remove tailing `/`
  if ([sourcePath length] > 0 && [[sourcePath substringFromIndex: [sourcePath length] - 1] isEqual:@"/"]) {
    sourcePath = [sourcePath substringToIndex: [sourcePath length] - 1];
  }

  if (!([sourcePath length] > 0 && [sourcePath hasPrefix:@"/"] &&
          ![sourcePath hasPrefix:@"/var/jb/"] && ![sourcePath hasPrefix:jbrootPath(@"/")])) {
    return -1;
  }

  NSFileManager *fm = [NSFileManager defaultManager];
  NSString *prefixersPlist = jbrootPath(@"/var/mobile/Library/Preferences/page.liam.prefixers.plist");
  if (check_existances && [fm fileExistsAtPath:prefixersPlist]) {
    NSDictionary *plistDict = [[NSDictionary alloc] initWithContentsOfFile:prefixersPlist];
    NSArray *sources = [plistDict objectForKey:@"source"];
    for (NSString* source in sources) {
      if ([source hasPrefix:sourcePath] || [sourcePath hasPrefix:source]) {
        return -2;
      }
    }
  }

  if (registerJbPrefixedPath(sourcePath, 1) == 0) {
    if (check_existances) {
      if ([fm fileExistsAtPath:prefixersPlist]) {
        NSMutableDictionary *plistDict = [[NSMutableDictionary alloc] initWithContentsOfFile:prefixersPlist];
        NSMutableArray *sources = [plistDict objectForKey:@"source"];
        [sources addObject:sourcePath];
        [plistDict writeToFile:prefixersPlist atomically:YES];
      } else {
        NSArray *sources = [[NSArray alloc] initWithObjects: sourcePath, nil];
        NSDictionary *plistDict = [[NSDictionary alloc] initWithObjectsAndKeys:sources, @"source", nil];
        [plistDict writeToFile:prefixersPlist atomically:YES];
      }
    }
    return 0;
  } else {
    return -3;
  }
}

int64_t bindUnmountPath(NSString *sourcePath) {
  // 0x00. normalization of `sourcePath`.
  sourcePath = [sourcePath stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
  // remove tailing `/`
  if ([sourcePath length] > 0 && [[sourcePath substringFromIndex: [sourcePath length] - 1] isEqual:@"/"]) {
    sourcePath = [sourcePath substringToIndex: [sourcePath length] - 1];
  }

  // 0x01. param check
  if (!([sourcePath length] > 0 && [sourcePath hasPrefix:@"/"] &&
          ![sourcePath hasPrefix:@"/var/jb/"] && ![sourcePath hasPrefix:jbrootPath(@"/")])) {
    return -1;
  }

  // 0x02. file check
  NSFileManager *fm = [NSFileManager defaultManager];
  NSString *prefixersPlist = jbrootPath(@"/var/mobile/Library/Preferences/page.liam.prefixers.plist");
  if (![fm fileExistsAtPath:prefixersPlist]) {
    return -2;
  }

  // 0x03. check if `sourcePath` already exists in `prefixersPlist`
  bool hasEqual = false;
  bool hasPrefixed = false;
  do {
    NSDictionary *plistDict = [[NSDictionary alloc] initWithContentsOfFile:prefixersPlist];
    NSArray *sources = [plistDict objectForKey:@"source"];
    for (NSString* source in sources) {
      if ([source isEqualToString: sourcePath]) {
        hasEqual = true;
      } else if ([source hasPrefix:sourcePath] || [sourcePath hasPrefix:source]) {
        hasPrefixed = true;
      }
    }
  } while (false);
  if (!hasEqual) {
    return 0;
  } else if (hasPrefixed) {
    return -3;
  }

  // 0x04. unmount and remove jbPrefixed-target files.
  run_unsandboxed(^{
    unmount(sourcePath.fileSystemRepresentation, 0);
  });
  NSString *jbPrefixedPath = jbrootPath(sourcePath);
  if ([fm fileExistsAtPath:jbPrefixedPath]) {
    // two cases: 1) this is the first time we need to create this path; 2) just removed an empty directory.
    for (int i = 0; i != 3 && [fm removeItemAtPath:jbPrefixedPath error:nil]; ++i) {}
  }

  // 0x05. remove item from plist
  NSMutableDictionary *plistDict = [[NSMutableDictionary alloc] initWithContentsOfFile:prefixersPlist];
  NSMutableArray *sources = [plistDict objectForKey:@"source"];
  NSPredicate *predicate = [NSPredicate predicateWithFormat: @"SELF != %@", sourcePath];
  [sources setArray:[sources filteredArrayUsingPredicate:predicate]];
  [plistDict writeToFile:prefixersPlist atomically:YES];

  return 0;
}
