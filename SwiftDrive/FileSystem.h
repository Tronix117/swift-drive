#import <Cocoa/Cocoa.h>
#import <OSXFUSE/OSXFUSE.h>

@interface FileSystem : NSObject

@property(readwrite, nonatomic, strong) GMUserFileSystem *FS;

@end