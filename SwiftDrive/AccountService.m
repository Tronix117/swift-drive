//
//  AccountService.m
//  SwiftDrive
//
//  Created by Jeremy Trufier on 11/03/2014.
//  Copyright (c) 2014 Jeremy Trufier. All rights reserved.
//

#import "AccountService.h"

@implementation AccountService

-(void) listContainerWithSuccess: (void (^)(AFHTTPRequestOperation *operation, id responseObject))success
                         failure: (void (^)(AFHTTPRequestOperation *operation, NSError *error))failure
{
    [manager GET:@"" parameters:nil xheaders:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"JSON: %@", responseObject);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error: %@", error);
    }];
}

@end
