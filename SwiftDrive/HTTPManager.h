//
//  HTTPManager.h
//  SwiftDrive
//
//  Created by Jeremy Trufier on 11/03/2014.
//  Copyright (c) 2014 Jeremy Trufier. All rights reserved.
//

#import "AFHTTPRequestOperationManager.h"

@class AccountService, ObjectService, ContainerService;
@interface HTTPManager : AFHTTPRequestOperationManager{
    dispatch_once_t oncePendingAuth;
    dispatch_queue_t operationQueue;
}

+ (id) sharedManager;

+ (AccountService *) account;
+ (ObjectService *) object;
+ (ContainerService *) container;

@property (readwrite, nonatomic, strong) NSURL *storageURL;
@property (readwrite, nonatomic, strong) NSURL *authURL;

@property (readonly, nonatomic, strong) AccountService *accountService;
@property (readonly, nonatomic, strong) ContainerService *containerService;
@property (readonly, nonatomic, strong) ObjectService *objectService;

-(void) GET: (NSString *)URLString
 parameters:(NSDictionary *)parameters
   xheaders: (NSDictionary *)xheaders
    success:(void (^)(id data, NSDictionary *headers))success
    failure:(void (^)(AFHTTPRequestOperation *, NSError *))failure;

@end
