//
//  ContainerService.m
//  SwiftDrive
//
//  Created by Jeremy Trufier on 11/03/2014.
//  Copyright (c) 2014 Jeremy Trufier. All rights reserved.
//

#import "ContainerService.h"
#import "ContainerStore.h"

@implementation ContainerService

-(NSArray *) listObjectsAtPathSync: (NSString *) path forContainer: (NSString *) containerName {
    dispatch_semaphore_t sema = dispatch_semaphore_create(0);
    
    __block id data = nil;
    [manager request:REST_GET forRessource:containerName withParameters:@{@"path": [path substringFromIndex:1]} andXHeaders:nil success:^(id response, NSDictionary *headers) {
        data = response;
        [[ContainerStore storeForContainer:containerName] updateWithArrayOfObject:response];
        dispatch_semaphore_signal(sema);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"error: %@", error);
        dispatch_semaphore_signal(sema);
    }];
    
    while (dispatch_semaphore_wait(sema, DISPATCH_TIME_NOW))
        CFRunLoopRunInMode(kCFRunLoopDefaultMode, 1.0, YES);
    
    return data;
}

@end
