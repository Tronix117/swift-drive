#import "FileSystem.h"
#import <OSXFUSE/OSXFUSE.h>
#import "ContainerService.h"
#import "ContainerStore.h"
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
    //NSLog(@"contentsOfDirectoryAtPath");
    //if ([path isEqualToString:@"/"]) {
    NSArray *list = [[HTTPManager container] listObjectsAtPathSync:path forContainer: @"default"];
    NSMutableArray *outlist = [NSMutableArray array];

    [list enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [outlist addObject:[[obj objectForKey:@"name"] lastPathComponent]];
        
//        NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
//        if ([[obj objectForKey:@"content_type"] isEqualToString:@"application/directory"]) {
//            [attributes setObject:NSFileTypeDirectory forKey:NSFileType];
//        }
//        [attributes setObject:[NSNumber numberWithInteger:[[obj objectForKey:@"bytes"] integerValue]] forKey:NSFileSize];
//        
//        NSLog(@"attributes/path: %@, %@", attributes, [NSString stringWithFormat:@"/%@", [obj objectForKey:@"name"]]);
//
//        [_FS setAttributes:attributes ofItemAtPath:[NSString stringWithFormat:@"/%@", [obj objectForKey:@"name"]] userData:nil error:error];
    }];
    
    return outlist;
    //    }
    //    if ( error ) {
    //        *error = [NSError errorWithPOSIXCode:ENOENT];
    //    }
    //    return nil;
}

- (NSData *)contentsAtPath:(NSString *)path {
    //NSLog(@"contentsAtPath");
    if ([[ContainerStore storeForContainer:@"default"] objectAtPath:path] != nil) {
        return [[HTTPManager object] getContentSyncAtPath:path forContainer: @"default"];
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

@end