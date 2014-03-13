//
//  AppDelegate.m
//  SwiftDrive
//
//  Created by Jeremy Trufier on 10/03/2014.
//  Copyright (c) 2014 Jeremy Trufier. All rights reserved.
//

#import "AppDelegate.h"
#import "FileSystem.h"
#import <OSXFUSE/OSXFUSE.h>
#import "AccountService.h"
#import "ContainerService.h"

@implementation AppDelegate

- (void)didMount:(NSNotification *)notification {
    NSDictionary* userInfo = [notification userInfo];
    NSString* mountPath = [userInfo objectForKey:kGMUserFileSystemMountPathKey];
    NSString* parentPath = [mountPath stringByDeletingLastPathComponent];
    [[NSWorkspace sharedWorkspace] selectFile:mountPath
                     inFileViewerRootedAtPath:parentPath];
}

- (void)didUnmount:(NSNotification*)notification {
    [[NSApplication sharedApplication] terminate:nil];
}

/*- (void)applicationDidFinishLaunching:(NSNotification *)notification {
    NSNotificationCenter* center = [NSNotificationCenter defaultCenter];
    [center addObserver:self selector:@selector(didMount:)
                   name:kGMUserFileSystemDidMount object:nil];
    [center addObserver:self selector:@selector(didUnmount:)
                   name:kGMUserFileSystemDidUnmount object:nil];
    
    NSString* mountPath = @"/Volumes/Hello";
    FileSystem* hello = [[FileSystem alloc] init];
    fs_ = [[GMUserFileSystem alloc] initWithDelegate:hello isThreadSafe:YES];
    NSMutableArray* options = [NSMutableArray array];
    [options addObject:@"rdonly"];
    [options addObject:@"volname=HelloFS"];
    [options addObject:[NSString stringWithFormat:@"volicon=%@",
                        [[NSBundle mainBundle] pathForResource:@"Fuse" ofType:@"icns"]]];
    [fs_ mountAtPath:mountPath withOptions:options];
}*/

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [fs_ unmount];  // Just in case we need to unmount;
    //[[fs_ delegate] release];  // Clean up HelloFS
    //[fs_ release];
    return NSTerminateNow;
}

- (void)mountFailed:(NSNotification *)notification {
    NSDictionary* userInfo = [notification userInfo];
    NSError* error = [userInfo objectForKey:kGMUserFileSystemErrorKey];
    NSLog(@"kGMUserFileSystem Error: %@, userInfo=%@", error, [error userInfo]);
    NSRunAlertPanel(@"Mount Failed", [error localizedDescription], nil, nil, nil);
    [[NSApplication sharedApplication] terminate:nil];
}

- (void)applicationDidFinishLaunching:(NSNotification *)notification {
    // Pump up our url cache.
    NSURLCache* cache = [NSURLCache sharedURLCache];
    [cache setDiskCapacity:(1024 * 1024 * 500)];
    [cache setMemoryCapacity:(1024 * 1024 * 40)];
    
    NSNotificationCenter* center = [NSNotificationCenter defaultCenter];
    [center addObserver:self selector:@selector(mountFailed:)
                   name:kGMUserFileSystemMountFailed object:nil];
    [center addObserver:self selector:@selector(didMount:)
                   name:kGMUserFileSystemDidMount object:nil];
    [center addObserver:self selector:@selector(didUnmount:)
                   name:kGMUserFileSystemDidUnmount object:nil];
    
    NSString* mountPath = @"/Volumes/SwiftDrive";
    fs_delegate_ = [[FileSystem alloc] init];
    fs_ = [[GMUserFileSystem alloc] initWithDelegate:fs_delegate_ isThreadSafe:YES];
    [fs_delegate_ setFS: fs_];
    
    NSMutableArray* options = [NSMutableArray array];
    NSString* volArg = [NSString stringWithFormat:@"volicon=%@", [[NSBundle mainBundle] pathForResource:@"HDRVIcon" ofType:@"icns"]];
    [options addObject:volArg];
    [options addObject:@"volname=SwiftDrive"];
    [options addObject:@"rdonly"];
    [fs_ mountAtPath:mountPath withOptions:options];
}

@end
