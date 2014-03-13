#import "FileSystem.h"
#import <OSXFUSE/OSXFUSE.h>
#import "ContainerService.h"
#import "ContainerStore.h"
#import "AccountService.h"
#import "ObjectService.h"

// Category on NSError to  simplify creating an NSError based on posix errno.
@interface NSError (POSIX)
+ (NSError *)errorWithPOSIXCode:(int)code;
@end
@implementation NSError (POSIX)
+ (NSError *)errorWithPOSIXCode:(int) code {
    return [NSError errorWithDomain:NSPOSIXErrorDomain code:code userInfo:nil];
}
@end

@implementation FileSystem

- (NSArray *)contentsOfDirectoryAtPath:(NSString *)path error:(NSError **)error {
    NSArray *list = [[RESTManager container] listObjectsAtPathSync:path forContainer: @"default"];
    NSMutableArray *outlist = [NSMutableArray array];

    [list enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [outlist addObject:[[obj objectForKey:@"name"] lastPathComponent]];
    }];
    
    return outlist;
}

- (NSData *)contentsAtPath:(NSString *)path {
    if ([[ContainerStore storeForContainer:@"default"] objectAtPath:path] != nil) {
        return [[RESTManager object] getContentSyncAtPath:path forContainer: @"default"];
    }
    return [NSData data];
}

#pragma optional Custom Icon

- (NSDictionary *)finderAttributesAtPath:(NSString *)path
                                   error:(NSError **)error {
    //NSLog(@"finderAttributesAtPath");
    return nil;
}

- (NSDictionary *)resourceAttributesAtPath:(NSString *)path
                                     error:(NSError **)error {
    //NSLog(@"resourceAttributesAtPath");
    return nil;
}

- (NSDictionary *) attributesOfItemAtPath:(NSString *)path userData:(id)userData error:(NSError *__autoreleasing *)error {
    NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
    
    if ([path isEqualToString:@"/"]) {
        [attributes setObject:[NSDate date] forKey:NSFileModificationDate];
        [attributes setObject:[NSDate date] forKey:NSFileCreationDate];
        
        return attributes;
    }
    
    NSDictionary *object = [[ContainerStore storeForContainer:@"default"] objectAtPath:path];
    if (object != nil) {
        if ([[object objectForKey:@"content_type"] isEqualToString:@"application/directory"]) {
            [attributes setObject:NSFileTypeDirectory forKey:NSFileType];
        }
        [attributes setObject:[NSNumber numberWithInteger:[[object objectForKey:@"bytes"] integerValue]] forKey:NSFileSize];
        
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setTimeZone:[NSTimeZone timeZoneWithName:@"GMT"]];
        [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSSSSS"];
        [attributes setObject:[dateFormatter dateFromString:[object objectForKey:@"last_modified"]] forKey:NSFileModificationDate];
    }
    return attributes;
}

//
//NSFileSystemSize
//NSFileSystemFreeSize
//NSFileSystemNodes
//NSFileSystemFreeNodes
//kGMUserFileSystemVolumeSupportsExtendedDatesKey
- (NSDictionary *)attributesOfFileSystemForPath:(NSString *)path error:(NSError **)error {
    
    NSDictionary *details = [[RESTManager account] getAccountDetailsSyncAndCacheFor:60]; // we fetch it every 60 seconds, not critical
    
    NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
    NSDictionary *container = [[details objectForKey:@"containers"] objectForKey:@"default"];
    NSDictionary *container_segments = [[details objectForKey:@"containers"] objectForKey:@"default_segments"];
    
    NSNumber *totalSpace = [NSNumber numberWithLongLong: [[details objectForKey:@"byte-free"] longLongValue]];
    NSNumber *freeSize = [NSNumber numberWithLongLong:[totalSpace longLongValue] - [[container objectForKey:@"bytes"] longLongValue] - [[container_segments objectForKey:@"bytes"] longLongValue]];

    [attributes setObject:totalSpace forKey:NSFileSystemSize];
    [attributes setObject:freeSize forKey:NSFileSystemFreeSize];
    
    return attributes;
}


//NSFileSize
//NSFileOwnerAccountID
//NSFileGroupOwnerAccountID
//NSFilePosixPermissions
//NSFileModificationDate
//NSFileCreationDate (if supports extended dates)
//kGMUserFileSystemFileBackupDateKey (if supports extended dates)
//kGMUserFileSystemFileChangeDateKey
//kGMUserFileSystemFileAccessDateKey
//kGMUserFileSystemFileFlagsKey
// everything else should be ignored
- (BOOL)setAttributes:(NSDictionary *)attributes ofItemAtPath:(NSString *)path userData:(id)userData error:(NSError **)error {
    return YES;
}

- (BOOL)openFileAtPath:(NSString *)path mode:(int)mode userData:(id *)userData error:(NSError **)error {
    // perhaps locking mecanism ?
    return YES;
}

- (void)releaseFileAtPath:(NSString *)path userData:(id)userData {
    // perhaps remove lock ?
}

- (int)readFileAtPath:(NSString *)path userData:(id)userData buffer:(char *)buffer size:(size_t)size offset:(off_t)offset error:(NSError **)error {
    return -1; //The number of bytes read or -1 on error.
}

- (int)writeFileAtPath:(NSString *)path userData:(id)userData buffer:(const char *)buffer size:(size_t)size offset:(off_t)offset error:(NSError **)error {
    
    return size; // The number of bytes written or -1 on error.
}

- (BOOL)exchangeDataOfItemAtPath:(NSString *)path1 withItemAtPath:(NSString *)path2 error:(NSError **)error {
    return NO;
}

- (BOOL)createDirectoryAtPath:(NSString *)path attributes:(NSDictionary *)attributes error:(NSError **)error {
    return NO;
}

- (BOOL)createFileAtPath:(NSString *)path attributes:(NSDictionary *)attributes userData:(id *)userData error:(NSError **)error {
    return NO;
}

- (BOOL)moveItemAtPath:(NSString *)source toPath:(NSString *)destination error:(NSError **)error {
    return NO;
}

- (BOOL)removeDirectoryAtPath:(NSString *)path error:(NSError **)error {
    return NO;
}

- (BOOL)removeItemAtPath:(NSString *)path error:(NSError **)error {
    return NO;
}

- (BOOL)linkItemAtPath:(NSString *)path toPath:(NSString *)otherPath error:(NSError **)error {
    return NO;
}

- (BOOL)createSymbolicLinkAtPath:(NSString *)path withDestinationPath:(NSString *)otherPath error:(NSError **)error {
    return NO;
}

- (NSString *)destinationOfSymbolicLinkAtPath:(NSString *)path error:(NSError **)error {
    return nil;
}

- (NSArray *)extendedAttributesOfItemAtPath:path error:(NSError **)error {
    return nil;
}

- (NSData *)valueOfExtendedAttribute:(NSString *)name ofItemAtPath:(NSString *)path position:(off_t)position error:(NSError **)error {
    return nil;
}

- (BOOL)setExtendedAttribute:(NSString *)name ofItemAtPath:(NSString *)path value:(NSData *)value position:(off_t)position options:(int)options error:(NSError **)error {
    return NO;
}

- (BOOL)removeExtendedAttribute:(NSString *)name ofItemAtPath:(NSString *)path error:(NSError **)error {
    return NO;
}


@end