#import "FileSystem.h"
#import <OSXFUSE/OSXFUSE.h>

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
    NSLog(@"contentsOfDirectoryAtPath");
    if ([path isEqualToString:@"/"]) {
        return [NSArray arrayWithObjects:@"coucou.jpg", @"ceci", @"est", @"mon", @"disque", @"dur", @"virtuel", nil];
    }
    if ( error ) {
        *error = [NSError errorWithPOSIXCode:ENOENT];
    }
    return nil;
}

- (NSData *)contentsAtPath:(NSString *)path {
    NSLog(@"contentsAtPath");
    return [NSData data];
}

#pragma optional Custom Icon

- (NSDictionary *)finderAttributesAtPath:(NSString *)path
                                   error:(NSError **)error {
    NSLog(@"finderAttributesAtPath");
    return nil;
}

- (NSDictionary *)resourceAttributesAtPath:(NSString *)path
                                     error:(NSError **)error {
    NSLog(@"resourceAttributesAtPath");
    return nil;
}

@end