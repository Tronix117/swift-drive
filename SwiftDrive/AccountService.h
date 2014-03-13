//
//  AccountService.h
//  SwiftDrive
//
//  Created by Jeremy Trufier on 11/03/2014.
//  Copyright (c) 2014 Jeremy Trufier. All rights reserved.
//

#import "BaseService.h"

@interface AccountService : BaseService

-(void) listContainerWithSuccess: (void (^)(AFHTTPRequestOperation *operation, id responseObject))success
                         failure: (void (^)(AFHTTPRequestOperation *operation, NSError *error))failure;

@end
