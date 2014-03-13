//
//  BaseService.m
//  SwiftDrive
//
//  Created by Jeremy Trufier on 11/03/2014.
//  Copyright (c) 2014 Jeremy Trufier. All rights reserved.
//

#import "BaseService.h"

@implementation BaseService

- (id) init {
    return [self initWithManager: [RESTManager sharedManager]];
}

- (id) initWithManager: (RESTManager *) httpmanager{
    if (self = [super init]) {
        manager = httpmanager;
    }
    return self;
}

@end
