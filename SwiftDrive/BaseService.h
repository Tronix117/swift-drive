//
//  BaseService.h
//  SwiftDrive
//
//  Created by Jeremy Trufier on 11/03/2014.
//  Copyright (c) 2014 Jeremy Trufier. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RESTManager.h"

@interface BaseService : NSObject {
    RESTManager *manager;
}

- (id) initWithManager: (RESTManager *) httpmanager;

@end
