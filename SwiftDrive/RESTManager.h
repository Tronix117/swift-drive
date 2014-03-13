//
//  HTTPManager.h
//  SwiftDrive
//
//  Created by Jeremy Trufier on 11/03/2014.
//  Copyright (c) 2014 Jeremy Trufier. All rights reserved.
//

#import "AFHTTPRequestOperationManager.h"

#define REST_GET     0
#define REST_HEAD    1
#define REST_POST    2
#define REST_PUT     3
#define REST_DELETE  4
#define REST_TRACE   5
#define REST_OPTIONS 6
#define REST_CONNECT 7
#define REST_PATCH   8


@class AccountService, ObjectService, ContainerService;
@interface RESTManager : AFHTTPRequestOperationManager{
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

- (void)request: (int)restCommand
   forRessource: (NSString *)ressource
        success: (void (^)(AFHTTPRequestOperation *operation, id responseObject))success
        failure: (void (^)(AFHTTPRequestOperation *operation, NSError *error))failure;

- (void)request: (int)restCommand
   forRessource: (NSString *)ressource
 withParameters: (NSDictionary *)parameters
        success: (void (^)(AFHTTPRequestOperation *operation, id responseObject))success
        failure: (void (^)(AFHTTPRequestOperation *operation, NSError *error))failure;

- (void)request: (int)restCommand
   forRessource: (NSString *)ressource
 withParameters: (NSDictionary *)parameters
    andXHeaders: (NSDictionary *)xheaders
        success: (void (^)(AFHTTPRequestOperation *operation, id responseObject))success
        failure: (void (^)(AFHTTPRequestOperation *operation, NSError *error))failure;

- (void)request: (int)restCommand
   forRessource: (NSString *)ressource
 withParameters: (NSDictionary *)parameters
    andXHeaders: (NSDictionary *)xheaders
andBuildBodyWithBlock: (void (^)(id <AFMultipartFormData> formData))bodyBlock
        success: (void (^)(AFHTTPRequestOperation *operation, id responseObject))success
        failure: (void (^)(AFHTTPRequestOperation *operation, NSError *error))failure;

@end
