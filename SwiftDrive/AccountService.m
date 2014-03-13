//
//  AccountService.m
//  SwiftDrive
//
//  Created by Jeremy Trufier on 11/03/2014.
//  Copyright (c) 2014 Jeremy Trufier. All rights reserved.
//

#import "AccountService.h"

@implementation AccountService

-(NSDictionary *) getAccountDetailsSyncAndCacheFor: (NSTimeInterval) timeInterval {
    dispatch_once(&cacheToken, ^{
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, timeInterval * NSEC_PER_SEC);
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            cacheToken = 0;
        });
        
        dispatch_semaphore_t sema = dispatch_semaphore_create(0);
        
        NSLog(@"getAccountDetails");
        [manager request:REST_GET forRessource: @"" success:^(id response, NSDictionary *headers) {
            cacheAccount = [NSMutableDictionary dictionaryWithDictionary: @{
                     @"object-count": [headers objectForKey:@"X-Account-Object-Count"],
                     @"meta-quota": [headers objectForKey:@"X-Account-Meta-Quota"],
                     @"byte-used": [headers objectForKey:@"X-Account-Bytes-Used"],
                     @"container-count": [headers objectForKey:@"X-Account-Container-Count"],
                     @"byte-free": [NSString stringWithFormat:@"%lli", [[headers objectForKey:@"X-Account-Meta-Quota"] longLongValue] - [[headers objectForKey:@"X-Account-Container-Count"] longLongValue]]
                     }];
            
            NSMutableDictionary *containers = [NSMutableDictionary dictionary];
            
            [((NSArray *) response) enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                [containers setObject:obj forKey:[obj objectForKey:@"name"]];
            }];
            
            [cacheAccount setObject:containers forKey:@"containers"];
            
            dispatch_semaphore_signal(sema);
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            NSLog(@"error: %@", error);
            dispatch_semaphore_signal(sema);
        }];
        
        while (dispatch_semaphore_wait(sema, DISPATCH_TIME_NOW))
            CFRunLoopRunInMode(kCFRunLoopDefaultMode, 1.0, YES);
        
    });
    
    return cacheAccount;
}

@end
