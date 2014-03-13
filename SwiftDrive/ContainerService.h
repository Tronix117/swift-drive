//
//  ContainerService.h
//  SwiftDrive
//
//  Created by Jeremy Trufier on 11/03/2014.
//  Copyright (c) 2014 Jeremy Trufier. All rights reserved.
//

#import "BaseService.h"

@interface ContainerService : BaseService

-(NSArray *) listObjectsAtPathSync: (NSString *) path forContainer: (NSString *) containerName;

@end
