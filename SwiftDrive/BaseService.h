//
//  BaseService.h
//  SwiftDrive
//
//  Created by Jeremy Trufier on 11/03/2014.
//  Copyright (c) 2014 Jeremy Trufier. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HTTPManager.h"

@interface BaseService : NSObject {
    HTTPManager *manager;
}

- (id) initWithManager: (HTTPManager *) httpmanager;

@end
