//
//  AppDelegate.h
//  SwiftDrive
//
//  Created by Jeremy Trufier on 10/03/2014.
//  Copyright (c) 2014 Jeremy Trufier. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class GMUserFileSystem;
@class FileSystem;

@interface AppDelegate : NSObject <NSApplicationDelegate> {
    GMUserFileSystem* fs_;
    FileSystem* fs_delegate_;
}

@property (assign) IBOutlet NSWindow *window;

@end
