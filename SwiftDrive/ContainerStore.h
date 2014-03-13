//
//  ContainerStore.h
//  SwiftDrive
//
//  Created by Jeremy Trufier on 12/03/2014.
//  Copyright (c) 2014 Jeremy Trufier. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ContainerStore : NSObject {
    NSMutableDictionary *dict;
}

+ (instancetype) storeForContainer: (NSString *)containerName;
- (void) updateWithArrayOfObject: (NSArray *)objects;
- (NSDictionary *) objectAtPath: (NSString *)path;

@end
