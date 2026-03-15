#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ViPERBridge : NSObject

- (instancetype)init;
- (void)processAudio:(float *)buffer frameCount:(uint32_t)frameCount;
- (void)setParameter:(int)param value1:(int)v1 value2:(int)v2
               value3:(int)v3 value4:(int)v4;
- (void)setParameterWithData:(int)param data:(NSData *)data;
- (void)setSamplingRate:(uint32_t)rate;
- (uint32_t)getSamplingRate;
- (uint64_t)getProcessTimeMs;
- (uint32_t)getConvolverKernelID;

@end

NS_ASSUME_NONNULL_END
