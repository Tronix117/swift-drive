//
//  ContainerStore.m
//  SwiftDrive
//
//  Created by Jeremy Trufier on 12/03/2014.
//  Copyright (c) 2014 Jeremy Trufier. All rights reserved.
//

#import "ContainerStore.h"

static NSMutableDictionary *stores = nil;

@implementation ContainerStore

- (id) init {
    if (self = [super init]) {
        dict = [NSMutableDictionary dictionary];
    }
    
    return self;
}

+ (instancetype)storeForContainer: (NSString *)containerName {
    static dispatch_once_t onceInitStoresToken;
    
    dispatch_once(&onceInitStoresToken, ^{
        stores = [NSMutableDictionary dictionary];
    });
    
    ContainerStore *store = nil;
    
    if((store = [stores objectForKey:containerName]) == nil){
        store = [[ContainerStore alloc] init];
        [stores setObject: store forKey:containerName];
    }
    
    return store;
}

- (void) updateWithArrayOfObject: (NSArray *)objects {
    [objects enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [dict setObject: obj forKey:[obj valueForKey:@"name"]];
    }];
}

- (NSDictionary *) objectAtPath: (NSString *)path {
    return [dict objectForKey:[path substringWithRange:NSMakeRange(1, [path length]-1)]];
}

@end
