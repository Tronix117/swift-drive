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

@interface NSStream (BoundPairAdditions)
+ (void)createBoundInputStream:(NSInputStream **)inputStreamPtr outputStream:(NSOutputStream **)outputStreamPtr bufferSize:(NSUInteger)bufferSize;
@end

enum {
    kPostBufferSize = 32768
};

@implementation NSStream (BoundPairAdditions)

+ (void)createBoundInputStream:(NSInputStream **)inputStreamPtr outputStream:(NSOutputStream **)outputStreamPtr bufferSize:(NSUInteger)bufferSize
{
    CFReadStreamRef     readStream;
    CFWriteStreamRef    writeStream;
    
    assert( (inputStreamPtr != NULL) || (outputStreamPtr != NULL) );
    
    readStream = NULL;
    writeStream = NULL;
    
    CFStreamCreateBoundPair(
                            NULL,
                            ((inputStreamPtr  != nil) ? &readStream : NULL),
                            ((outputStreamPtr != nil) ? &writeStream : NULL),
                            (CFIndex) bufferSize);
    
    if (inputStreamPtr != NULL) {
    //    *inputStreamPtr  = [NSMakeCollectable(readStream) autorelease];
        *inputStreamPtr = CFBridgingRelease(readStream);
    }
    if (outputStreamPtr != NULL) {
        //    *outputStreamPtr = [NSMakeCollectable(writeStream) autorelease];
        *inputStreamPtr = CFBridgingRelease(readStream);
    }
}
@end

@implementation FileSystem

- (id) init {
    if (self = [super init]) {
        tempAttributes = [NSMutableDictionary dictionary];
        tempStream = [NSMutableDictionary dictionary];
    }
    return self;
}

- (NSArray *)contentsOfDirectoryAtPath:(NSString *)path error:(NSError **)error {
    NSArray *list = [[RESTManager container] listObjectsAtPathSync:path forContainer: self.containerName];
    NSMutableArray *outlist = [NSMutableArray array];

    [list enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [outlist addObject:[[obj objectForKey:@"name"] lastPathComponent]];
    }];
    
    return outlist;
}

- (NSData *)contentsAtPath:(NSString *)path {
    if ([[ContainerStore storeForContainer:self.containerName] objectAtPath:path] != nil) {
        return [[RESTManager object] getContentSyncAtPath:path forContainer: self.containerName];
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
    
    NSDictionary *object = [[ContainerStore storeForContainer:self.containerName] objectAtPath:path];
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
    NSDictionary *container = [[details objectForKey:@"containers"] objectForKey:self.containerName];
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
    NSLog(@"writeFileAtPath... size: %zu offset: %lli userData: %@",size, offset, userData);
    
    NSInputStream *inputStream;
    NSOutputStream *outputStream;
    
//    NSInputStream *inputStream;
//    NSOutputStream *outputStream;
    //[inputStream open];
    //NSStream *a;
    //dispatch_semaphore_t sema;
    
    NSMutableDictionary *streamIO;
    BOOL a= NO;
    if ((streamIO = [tempStream objectForKey:path]) == nil) {
        CFReadStreamRef readStream;
        CFWriteStreamRef writeStream;
        CFStreamCreateBoundPair(NULL, &readStream, &writeStream, 65536);
        
        inputStream = (__bridge NSInputStream *)readStream;
        outputStream = (__bridge NSOutputStream *)writeStream;
        
        streamIO = [NSMutableDictionary dictionary];
//        inputStream = [[NSInputStream alloc] init];
//        outputStream = [[NSOutputStream alloc] init];
//        [inputStream open];
//        [outputStream open];
        //a = [[NSStream alloc] init];
       
        //NSLog(@"input %@", inputStream);
        //NSLog(@"output %@", outputStream);
        //streamIO = [NSMutableDictionary dictionaryWithObjectsAndKeys:inputStream, @"input", outputStream, @"output", nil];
        [streamIO setObject:inputStream forKey:@"input"];
        [streamIO setObject:outputStream forKey:@"output"];
        //[NSStream createBoundInputStream:&inputStream outputStream:&outputStream bufferSize:1024 * 4];
        
        //sema = dispatch_semaphore_create(0);
        [inputStream open];
        [outputStream open];
        
        a=YES;
        //[[RESTManager object] putDataChunkedAtPath:path forContainer:self.containerName fromStream:inputStream];
        [tempStream setObject:streamIO forKey:path];
    } else {
        inputStream = [streamIO objectForKey:@"input"];
        outputStream = [streamIO objectForKey:@"output"];
    }
    NSLog(@"willwrite");
    [outputStream write:buffer maxLength:size];
    
//    uint8_t *buffer2[65536];
//    [inputStream read:buffer2 maxLength:65536];
//    NSLog(@"buffer2: %s", buffer2);
    if (a) {
        [[RESTManager object] putDataChunkedAtPath:path forContainer:self.containerName fromStream:inputStream];
    }

    NSLog(@"haswrite");
    if (size < 65536) {
        [outputStream close];
        //[inputStream close];
        //NSMutableString *hex = [NSMutableString string];
        //while ( *utf8 ) [hex appendFormat:@"%02X" , *utf8++ & 0x00FF];
        NSLog(@"buffer last: 0x%02X%02X%02X", buffer[size - 3] & 0x00FF, buffer[size - 2] & 0x00FF, buffer[size - 1] & 0x00FF);
    }
    
//    while (dispatch_semaphore_wait(sema, DISPATCH_TIME_NOW))
//        CFRunLoopRunInMode(kCFRunLoopDefaultMode, 1.0, YES);
    
//    unsigned int len;
//    uint8_t *buffer2;
//    [inputStream getBuffer:&buffer2 length:&len];
//    NSLog(@"len: %d", len);
    
//    while ([inputStream hasBytesAvailable])
//        CFRunLoopRunInMode(kCFRunLoopDefaultMode, 1.0, YES);
    
    return size;
    
    
    //[outputStream];
    //return [[RESTManager object] putDataSyncAtPath:path forContainer:self.containerName withData:buffer andSize:size atOffset:offset andAttributes: nil] ? size : -1; // The number of bytes written or -1 on error.
    //return size;
}

- (BOOL)exchangeDataOfItemAtPath:(NSString *)path1 withItemAtPath:(NSString *)path2 error:(NSError **)error {
    NSLog(@"exchangeDataOfItemAtPath");
    return NO;
}

- (BOOL)createDirectoryAtPath:(NSString *)path attributes:(NSDictionary *)attributes error:(NSError **)error {
    NSLog(@"createDirectoryAtPath");
    return NO;//[[RESTManager object] putDataSyncAtPath: path withData: '' andAttributes: attributes];
}

- (BOOL)createFileAtPath:(NSString *)path attributes:(NSDictionary *)attributes userData:(id *)userData error:(NSError **)error {
    NSLog(@"createFileAtPath");
    return YES;//[[RESTManager object] putDataSyncAtPath: path withData: '' andAttributes: attributes];
}

- (BOOL)moveItemAtPath:(NSString *)source toPath:(NSString *)destination error:(NSError **)error {
    NSLog(@"moveItemAtPath");
    return NO;
}

- (BOOL)removeDirectoryAtPath:(NSString *)path error:(NSError **)error {
    NSLog(@"");
    return NO;
}

- (BOOL)removeItemAtPath:(NSString *)path error:(NSError **)error {
    NSLog(@"removeItemAtPath");
    return NO;
}

- (BOOL)linkItemAtPath:(NSString *)path toPath:(NSString *)otherPath error:(NSError **)error {
    NSLog(@"linkItemAtPath");
    return NO;
}

- (BOOL)createSymbolicLinkAtPath:(NSString *)path withDestinationPath:(NSString *)otherPath error:(NSError **)error {
    NSLog(@"createSymbolicLinkAtPath");
    return NO;
}

- (NSString *)destinationOfSymbolicLinkAtPath:(NSString *)path error:(NSError **)error {
    NSLog(@"destinationOfSymbolicLinkAtPath");
    return nil;
}

- (NSArray *)extendedAttributesOfItemAtPath:path error:(NSError **)error {
    NSLog(@"extendedAttributesOfItemAtPath");
    
    NSMutableArray *attributes = [NSMutableArray array];
    NSMutableDictionary *dict;
    if ((dict = [tempAttributes objectForKey:path]) != nil) {
        [dict enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            [attributes addObject:key];
        }];
    }
    
    return attributes;
}

- (NSData *)valueOfExtendedAttribute:(NSString *)name ofItemAtPath:(NSString *)path position:(off_t)position error:(NSError **)error {
    NSLog(@"valueOfExtendedAttribute");
    
    NSMutableDictionary *dict;
    if ((dict = [tempAttributes objectForKey:path]) != nil) {
        return [dict objectForKey:name];
    }
    
    return nil;
}

- (BOOL)setExtendedAttribute:(NSString *)name ofItemAtPath:(NSString *)path value:(NSData *)value position:(off_t)position options:(int)options error:(NSError **)error
{
    NSLog(@"setExtendedAttribute: %@ value: %s position: %llu options: %i", name, [value bytes], position, options);
    
    NSMutableDictionary *dict;
    if ((dict = [tempAttributes objectForKey:path]) == nil) {
        [tempAttributes setObject:(dict = [NSMutableDictionary dictionary]) forKey:path];
    }
    [dict setObject:value forKey:name];
    
    return YES;
}

- (BOOL)removeExtendedAttribute:(NSString *)name ofItemAtPath:(NSString *)path error:(NSError **)error {
    NSLog(@"removeExtendedAttribute");
    
    NSMutableDictionary *dict;
    if ((dict = [tempAttributes objectForKey:path]) == nil) {
        [dict removeObjectForKey:path];
    }

    return NO;
}


@end