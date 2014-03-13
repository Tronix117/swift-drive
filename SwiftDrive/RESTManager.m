//
//  HTTPManager.m
//  SwiftDrive
//
//  Created by Jeremy Trufier on 11/03/2014.
//  Copyright (c) 2014 Jeremy Trufier. All rights reserved.
//

#import "RESTManager.h"
#import "AccountService.h"
#import "ObjectService.h"
#import "ContainerService.h"

@interface RESTManager()

@property (readwrite, nonatomic, strong) AccountService *accountService;
@property (readwrite, nonatomic, strong) ContainerService *containerService;
@property (readwrite, nonatomic, strong) ObjectService *objectService;

@end

@implementation RESTManager

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

#pragma mark - Singleton accessors

+ (id)sharedManager {
    static BaseService *sharedManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedManager = [[self alloc] init];
    });
    return sharedManager;
}

+(ContainerService *)container {
    return [[RESTManager sharedManager] containerService];
}

+(ObjectService *)object {
    return [[RESTManager sharedManager] objectService];
}

+(AccountService *)account {
    return [[RESTManager sharedManager] accountService];
}

#pragma mark - Authentication

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

#pragma mark - REST requests & aliases
- (void)request: (int)restCommand
   forRessource: (NSString *)ressource
        success: (void (^)(AFHTTPRequestOperation *operation, id responseObject))success
        failure: (void (^)(AFHTTPRequestOperation *operation, NSError *error))failure
{
    [self request:restCommand forRessource:ressource withParameters:nil andXHeaders:nil andBuildBodyWithBlock:nil success:success failure:failure];
}

- (void)request: (int)restCommand
   forRessource: (NSString *)ressource
 withParameters: (NSDictionary *)parameters
        success: (void (^)(AFHTTPRequestOperation *operation, id responseObject))success
        failure: (void (^)(AFHTTPRequestOperation *operation, NSError *error))failure
{
    [self request:restCommand forRessource:ressource withParameters:parameters andXHeaders:nil andBuildBodyWithBlock:nil success:success failure:failure];
}

- (void)request: (int)restCommand
   forRessource: (NSString *)ressource
 withParameters: (NSDictionary *)parameters
    andXHeaders: (NSDictionary *)xheaders
        success: (void (^)(AFHTTPRequestOperation *operation, id responseObject))success
        failure: (void (^)(AFHTTPRequestOperation *operation, NSError *error))failure
{
    [self request:restCommand forRessource:ressource withParameters:parameters andXHeaders:xheaders andBuildBodyWithBlock:nil success:success failure:failure];
}

- (void)request: (int)restCommand
   forRessource: (NSString *)ressource
 withParameters: (NSDictionary *)parameters
    andXHeaders: (NSDictionary *)xheaders
andBuildBodyWithBlock: (void (^)(id <AFMultipartFormData> formData))bodyBlock
        success: (void (^)(AFHTTPRequestOperation *operation, id responseObject))success
        failure: (void (^)(AFHTTPRequestOperation *operation, NSError *error))failure
{
    if (self.storageURL == nil) {
        dispatch_suspend(operationQueue);
        [self auth];
    }
    
    // Using a queue to be able to suspend whenever we want, for exemple when token needs to be renewed or when internet connection is lost
    dispatch_async(operationQueue, ^{
        NSString *command;
        switch (restCommand) {
            case REST_GET:
                command = @"GET";
                break;
            case REST_HEAD:
                command = @"HEAD";
                break;
            case REST_POST:
                command = @"POST";
                break;
            case REST_PUT:
                command = @"PUT";
                break;
            case REST_DELETE:
                command = @"DELETE";
                break;
            case REST_TRACE:
                command = @"TRACE";
                break;
            case REST_OPTIONS:
                command = @"OPTIONS";
                break;
            case REST_CONNECT:
                command = @"CONNECT";
                break;
            case REST_PATCH:
                command = @"PATCH";
                break;
            default:
                command = @"GET";
                break;
        }
        
        NSLog(@"%@: %@", command, ressource);
        
        NSMutableURLRequest *request = [self.requestSerializer requestWithMethod:command
                                                                       URLString:[[NSURL URLWithString:ressource relativeToURL:self.storageURL] absoluteString]
                                                                      parameters:parameters
                                                                           error:nil];
        
        [xheaders enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSString *obj, BOOL *stop) {
            [request setValue:obj forHTTPHeaderField:[NSString stringWithFormat:@"X-%@", key]];
        }];
        
        AFHTTPRequestOperation *operation = [self HTTPRequestOperationWithRequest:request success:^(AFHTTPRequestOperation *operation, id responseObject) {
            success(responseObject, [operation.response allHeaderFields]);
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            // if need_auth {
            dispatch_suspend(operationQueue);
            [self request:restCommand forRessource:ressource withParameters:parameters andXHeaders:xheaders andBuildBodyWithBlock:bodyBlock success:success failure:failure];
            //}
            failure(operation, error);
        }];
        [self.operationQueue addOperation:operation];
    });
}
@end
