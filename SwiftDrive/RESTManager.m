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
#import "BBHTTP.h"

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
        
        self.requestSerializer = [AFHTTPRequestSerializer serializer];
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
        [request setValue:@"[auth-key]" forHTTPHeaderField:@"X-Auth-Key"];
        
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
    [self request:restCommand forRessource:ressource withParameters:nil andXHeaders:nil andBody:nil success:success failure:failure];
}

- (void)request: (int)restCommand
   forRessource: (NSString *)ressource
 withParameters: (NSDictionary *)parameters
        success: (void (^)(AFHTTPRequestOperation *operation, id responseObject))success
        failure: (void (^)(AFHTTPRequestOperation *operation, NSError *error))failure
{
    [self request:restCommand forRessource:ressource withParameters:parameters andXHeaders:nil andBody:nil success:success failure:failure];
}

- (void)request: (int)restCommand
   forRessource: (NSString *)ressource
 withParameters: (NSDictionary *)parameters
    andXHeaders: (NSDictionary *)xheaders
        success: (void (^)(AFHTTPRequestOperation *operation, id responseObject))success
        failure: (void (^)(AFHTTPRequestOperation *operation, NSError *error))failure
{
    [self request:restCommand forRessource:ressource withParameters:parameters andXHeaders:xheaders andBody:nil success:success failure:failure];
}

- (void)request: (int)restCommand
   forRessource: (NSString *)ressource
 withParameters: (NSDictionary *)parameters
    andXHeaders: (NSDictionary *)xheaders
        andBody: (id)body
        success: (void (^)(AFHTTPRequestOperation *operation, id responseObject))success
        failure: (void (^)(AFHTTPRequestOperation *operation, NSError *error))failure
{
    [self request:restCommand forRessource:ressource withParameters:parameters andXHeaders:xheaders andBody:body success:success failure:failure uploadProgress:nil];
}

- (void)request: (int)restCommand
   forRessource: (NSString *)ressource
 withParameters: (NSDictionary *)parameters
    andXHeaders: (NSDictionary *)xheaders
        andBody: (id)body
        success: (void (^)(AFHTTPRequestOperation *operation, id responseObject))success
        failure: (void (^)(AFHTTPRequestOperation *operation, NSError *error))failure
 uploadProgress: (void (^)(NSUInteger bytesWritten, NSInteger totalBytesWritten, NSInteger totalBytesExpectedToWrite))uploadProgress
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
        NSMutableURLRequest *request;
        NSString *url = [[NSURL URLWithString:ressource relativeToURL:self.storageURL] absoluteString];
        
        request = [self.requestSerializer requestWithMethod:command
                                                  URLString: url
                                                 parameters:parameters
                                                      error:nil];
        
        if (body != nil) {
//            if ([body isKindOfClass:[NSInputStream class]]) {
//                NSLog(@"ISStream");
//                [request setHTTPBodyStream:body];
//                [request setValue:@"chunked" forHTTPHeaderField:@"Transfer-Encoding"];
//            } else
                if ([body isKindOfClass:[NSData class]]) {
                [request setHTTPBody:body];
                //[request setValue:[NSString stringWithFormat:@"%lu", (unsigned long)[((NSData *) body) length]] forHTTPHeaderField:@"Content-Length"];
            }
        }
        
        [xheaders enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSString *obj, BOOL *stop) {
            [request setValue:obj forHTTPHeaderField:[NSString stringWithFormat:@"X-%@", key]];
        }];
        
        NSLog(@"REQUEST HEADERS: %@", request.allHTTPHeaderFields);
        
        if (body != nil) {
            NSMutableURLRequest *request2 = [[NSMutableURLRequest alloc] init];
            
            [request2 setValue:@"chunked" forHTTPHeaderField:@"Transfer-Encoding"];
            //[request2 setURL:[NSURL URLWithString:[NSString stringWithFormat:@"http%@", [url substringFromIndex:5]]]];
            [request2 setURL:[NSURL URLWithString:url]];
            [request2 setHTTPMethod:@"PUT"];
            [request2 setHTTPBodyStream:body];
            
            NSOperationQueue *queue = [[NSOperationQueue alloc] init];
            [NSURLConnection sendAsynchronousRequest:request2 queue:queue completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
                NSLog(@"AHHAHAHA %@ %@ %@", response, data, connectionError);
            }];
        } else {
            AFHTTPRequestOperation *operation = [self HTTPRequestOperationWithRequest:request success:^(AFHTTPRequestOperation *operation, id responseObject) {
                success(responseObject, [operation.response allHeaderFields]);
            } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                if(operation.response.statusCode == 401 || operation.response.statusCode == 403) {
                    [self auth];
                    dispatch_suspend(operationQueue);
                    [self request:restCommand forRessource:ressource withParameters:parameters andXHeaders:xheaders andBody:body success:success failure:failure];
                }
                failure(operation, error);
            }];
            
            if (body != nil && [body isKindOfClass:[NSInputStream class]]) {
                NSLog(@"stream: %@", body);
                [operation setInputStream:[NSInputStream inputStreamWithData:[NSData dataWithBytes:@"LOL" length:3]]];
                //[operation setInputStream:body];
                [request setValue:@"chunked" forHTTPHeaderField:@"Transfer-Encoding"];
                [request setValue:@"0" forHTTPHeaderField:@"Content-Length"];
            }
        
            if (uploadProgress) {
                NSLog(@"uploadProgress");
                [operation setUploadProgressBlock:uploadProgress];
            }
            
            NSLog(@"REQUEST HEADERS: %@", request.allHTTPHeaderFields);

            
            [self.operationQueue addOperation:operation];
        }
    });
}

- (void)requestup: (int)restCommand
   forRessource: (NSString *)ressource
 withParameters: (NSDictionary *)parameters
    andXHeaders: (NSDictionary *)xheaders
        andBody: (id)body
        success: (void (^)(AFHTTPRequestOperation *operation, id responseObject))success
        failure: (void (^)(AFHTTPRequestOperation *operation, NSError *error))failure
 uploadProgress: (void (^)(NSUInteger bytesWritten, NSInteger totalBytesWritten, NSInteger totalBytesExpectedToWrite))uploadProgress
{
//    [[BBHTTPRequest createResource:@"http://foo.bar/baz" withContentsOfFile:@"/path/to/file"]
//     setup:^(BBHTTPRequest* request) {
//         request[@"Extra-Header"] = @"something else";
//     } execute:^(BBHTTPResponse* response) {
//         // handle response
//     } error:nil];

    dispatch_async(operationQueue, ^{
        BBHTTPExecutor *executor = [[BBHTTPExecutor alloc] initWithId:@"hubic"];
        executor.maxParallelRequests = 10;
        BBHTTPRequest *request = [[BBHTTPRequest alloc] initWithURL:[NSURL URLWithString:ressource relativeToURL:self.storageURL]  andVerb:@"PUT"];
        
        [request setUploadStream:body withContentType:@"application/octet-stream" andSize:0];
        [request.headers setValue:[[self.requestSerializer HTTPRequestHeaders] valueForKey:@"X-Auth-Token"] forKey:@"X-Auth-Token"];
        
        [request setUploadProgressBlock: ^(NSUInteger current, NSUInteger total) {
            NSLog(@"D%lu/%lu", current, total);
        }];
        
        [request setCallbackQueue:operationQueue];
        [request setChunkedTransfer:YES];
        [request setConnectionTimeout:10];
        
        request.finishBlock = ^(BBHTTPRequest* request) {
            if ([request wasCancelled]) {
                // Handle request cancellation, only happens when you call the 'cancel' method
                NSLog(@"REQUEST: canceled");
            } else if ([request hasSuccessfulResponse]) {
                // Handle completed request with success response from server
                NSLog(@"REQUEST: hasSuccessfulResponse: %lu | %@", request.responseStatusCode, request.response.content);
            } else if ([request wasSuccessfullyExecuted]) {
                // Handle completed request with error response from server
                NSLog(@"REQUEST: wasSuccessfullyExecuted");
            } else {
                // Some other error occurred which prevented the request from terminating
                // The 'error' read-only property will be set
                NSLog(@"REQUEST: error: %@", request.error);
            }
        };
        
        [executor executeRequest:request];
    });
}
@end
