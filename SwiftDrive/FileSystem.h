#import <Cocoa/Cocoa.h>
#import <OSXFUSE/OSXFUSE.h>

@interface FileSystem : NSObject{
    NSMutableDictionary *tempAttributes;
    NSMutableDictionary *tempStream;
}

@property(readwrite, nonatomic, strong) NSString *containerName;
@property(readwrite, nonatomic, strong) NSInputStream *inputStream;
@property(readwrite, nonatomic, strong) NSOutputStream *outputStream;

@end