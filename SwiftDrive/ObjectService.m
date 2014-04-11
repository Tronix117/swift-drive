//
//  ObjectService.m
//  SwiftDrive
//
//  Created by Jeremy Trufier on 11/03/2014.
//  Copyright (c) 2014 Jeremy Trufier. All rights reserved.
//

#import "ObjectService.h"

@implementation ObjectService

-(NSData *) getContentSyncAtPath:(NSString *) path forContainer: (NSString *) containerName {
    dispatch_semaphore_t sema = dispatch_semaphore_create(0);
    
    __block id data = nil;
    [manager request:REST_GET forRessource:[containerName stringByAppendingString: path] success:^(id response, NSDictionary *headers) {
        data = response;
        dispatch_semaphore_signal(sema);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"error: %@", error);
        dispatch_semaphore_signal(sema);
    }];
    
    while (dispatch_semaphore_wait(sema, DISPATCH_TIME_NOW))
        CFRunLoopRunInMode(kCFRunLoopDefaultMode, 1.0, YES);
    
    return data;
}

-(BOOL) putDataSyncAtPath:(NSString *)path
             forContainer:(NSString *)containerName
                 withData:(const char *)buffer
                  andSize:(size_t)size
                 atOffset:(off_t)offset
            andAttributes:(NSDictionary *)attributes
{    
    dispatch_semaphore_t sema = dispatch_semaphore_create(0);
    
    NSData *data= [NSData dataWithBytes:buffer length:size];
    //NSInputStream *body = [[NSInputStream alloc] initWithData:data];
    NSData *body = data;
    __block BOOL result = NO;
    [manager request:REST_PUT forRessource:[containerName stringByAppendingString: path] withParameters:nil andXHeaders:nil andBody:body success:^(id response, NSDictionary *headers) {
        result = YES;
        dispatch_semaphore_signal(sema);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"error: %@", error);
        result = NO;
        dispatch_semaphore_signal(sema);
    }];
    
    while (dispatch_semaphore_wait(sema, DISPATCH_TIME_NOW))
        CFRunLoopRunInMode(kCFRunLoopDefaultMode, 1.0, YES);
    
    return NO;
}

-(void) putDataChunkedAtPath:(NSString *)path
                forContainer:(NSString *)containerName
                  fromStream:(NSInputStream *)inputStream
{
    [manager requestup:REST_PUT forRessource:[containerName stringByAppendingString: path] withParameters:nil andXHeaders:nil andBody:inputStream success:^(id response, NSDictionary *headers) {
        NSLog(@"File successfuly uploaded");
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"error: %@", error);
        NSLog(@"details: %lu / %@", operation.response.statusCode, operation.response.allHeaderFields);
    } uploadProgress:^(NSUInteger bytesWritten, NSInteger totalBytesWritten, NSInteger totalBytesExpectedToWrite) {
        NSLog(@"Bytes: %lu, %lu, %lu", bytesWritten, totalBytesWritten, totalBytesExpectedToWrite);
    }];
}
    
@end
