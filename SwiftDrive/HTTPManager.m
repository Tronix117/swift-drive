//
//  HTTPManager.m
//  SwiftDrive
//
//  Created by Jeremy Trufier on 11/03/2014.
//  Copyright (c) 2014 Jeremy Trufier. All rights reserved.
//

#import "HTTPManager.h"
#import "AccountService.h"
#import "ObjectService.h"
#import "ContainerService.h"

@interface HTTPManager()

@property (readwrite, nonatomic, strong) AccountService *accountService;
@property (readwrite, nonatomic, strong) ContainerService *containerService;
@property (readwrite, nonatomic, strong) ObjectService *objectService;

@end

@implementation HTTPManager

-(id) init {
    if (self = [super init]) {
        self.objectService = [[ObjectService alloc] initWithManager: self];
        self.containerService = [[ContainerService alloc] initWithManager: self];
        self.accountService = [[AccountService alloc] initWithManager: self];
        
        operationQueue = dispatch_queue_create("com.trufier.SwiftDrive.operations", DISPATCH_QUEUE_CONCURRENT);
        
        self.requestSerializer = [AFJSONRequestSerializer serializer];
        [self.requestSerializer setValue:@"application/json" forHTTPHeaderField:@"Accept"];
        
        self.responseSerializer = [AFCompoundResponseSerializer compoundSerializerWithResponseSerializers: @[[AFJSONResponseSerializer serializer], [AFHTTPResponseSerializer serializer]]];
        
        [self setAuthURL:[NSURL URLWithString:@"http://localhost/auth/v1.0"]];
    }
    return self;
}

+ (id)sharedManager {
    static BaseService *sharedManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedManager = [[self alloc] init];
    });
    return sharedManager;
}

+(ContainerService *)container {
    return [[HTTPManager sharedManager] containerService];
}

+(ObjectService *)object {
    return [[HTTPManager sharedManager] objectService];
}

+(AccountService *)account {
    return [[HTTPManager sharedManager] accountService];
}

-(void) auth {
    dispatch_once(&oncePendingAuth, ^{
        NSLog(@">>> Auth needed");
        
        NSMutableURLRequest *request = [self.requestSerializer requestWithMethod:@"GET" URLString: [self.authURL absoluteString] parameters:nil error:nil];
        
        [request setValue:@"hubic" forHTTPHeaderField:@"X-Auth-User"];
        [request setValue:@"gcpGyqanY0POxkrRNsvU2Yw89PeqJRa8WnjgUADRWfr9LCkPR3643dMX6kdwjhxI" forHTTPHeaderField:@"X-Auth-Key"];
        
        AFHTTPRequestOperation *operation = [self HTTPRequestOperationWithRequest:request
          success:^(AFHTTPRequestOperation *operation, id responseObject) {
              NSDictionary *headers = [operation.response allHeaderFields];

              [self.requestSerializer setValue:[headers objectForKey:@"X-Auth-Token"] forHTTPHeaderField: @"X-Auth-Token"];
              [self setStorageURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@/", [headers objectForKey:@"X-Storage-Url"]]]];
              
              NSLog(@"< Auth token: %@", [headers objectForKey:@"X-Auth-Token"]);
              NSLog(@"< Auth storage url: %@", [[self storageURL] absoluteString]);
              NSLog(@"<<< Auth success");
              
              oncePendingAuth = 0;
              dispatch_resume(operationQueue);
          }
          failure:^(AFHTTPRequestOperation *operation, NSError * error) {
              NSLog(@"<<< Auth error");
              oncePendingAuth = 0;
          }];
        [self.operationQueue addOperation:operation];
    });
}

-(void) GET: (NSString *)URLString
 parameters:(NSDictionary *)parameters
   xheaders: (NSDictionary *)xheaders
    success:(void (^)(id data, NSDictionary *headers))success
    failure:(void (^)(AFHTTPRequestOperation *, NSError *))failure
{
    if (self.storageURL == nil) {
        dispatch_suspend(operationQueue);
        [self auth];
    }
    
    // Using a queue to be able to suspend whenever we want, for exemple when token needs to be renewed or when internet connection is lost
    dispatch_async(operationQueue, ^{
        NSLog(@"GET: %@", [[NSURL URLWithString:URLString relativeToURL:self.storageURL] absoluteString]);
        NSMutableURLRequest *request = [self.requestSerializer requestWithMethod:@"GET" URLString:[[NSURL URLWithString:URLString relativeToURL:self.storageURL] absoluteString] parameters:parameters error:nil];
        
        [xheaders enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSString *obj, BOOL *stop) {
            [request setValue:obj forHTTPHeaderField:[NSString stringWithFormat:@"X-%@", key]];
        }];
        
        AFHTTPRequestOperation *operation = [self HTTPRequestOperationWithRequest:request success:^(AFHTTPRequestOperation *operation, id responseObject) {
            success(responseObject, [operation.response allHeaderFields]);
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            
            // if need_auth {
            dispatch_suspend(operationQueue);
            [self GET:URLString parameters:parameters xheaders:xheaders success:success failure:failure];
            //}
            failure(operation, error);
        }];
        [self.operationQueue addOperation:operation];
    });
}
@end
