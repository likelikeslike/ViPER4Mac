#import "ViPERBridge.h"
#include "viper/ViPER.h"
#include <os/lock.h>

@implementation ViPERBridge {
  ViPER _engine;
  os_unfair_lock _lock;
}

- (instancetype)init {
  self = [super init];
  if (self) {
    _lock = OS_UNFAIR_LOCK_INIT;
  }
  return self;
}

- (void)processAudio:(float *)buffer frameCount:(uint32_t)frameCount {
  std::vector<float> vec(buffer, buffer + frameCount * 2);
  os_unfair_lock_lock(&_lock);
  _engine.process(vec, frameCount);
  os_unfair_lock_unlock(&_lock);
  memcpy(buffer, vec.data(), frameCount * 2 * sizeof(float));
}

- (void)setParameter:(int)param
              value1:(int)v1
              value2:(int)v2
              value3:(int)v3
              value4:(int)v4 {
  os_unfair_lock_lock(&_lock);
  _engine.DispatchCommand(param, v1, v2, v3, v4, 0, nullptr);
  os_unfair_lock_unlock(&_lock);
}

- (void)setParameterWithData:(int)param data:(NSData *)data {
  os_unfair_lock_lock(&_lock);
  if (data.length == 8192) {
    const uint8_t *bytes = static_cast<const uint8_t *>(data.bytes);
    int value1 = *reinterpret_cast<const int *>(bytes);
    uint32_t arrSize = *reinterpret_cast<const uint32_t *>(bytes + sizeof(int));
    signed char *arr =
        const_cast<signed char *>(reinterpret_cast<const signed char *>(
            bytes + sizeof(int) + sizeof(uint32_t)));
    _engine.DispatchCommand(param, value1, 0, 0, 0, arrSize, arr);
  } else if (data.length == 256 || data.length == 1024) {
    const uint8_t *bytes = static_cast<const uint8_t *>(data.bytes);
    uint32_t arrSize = *reinterpret_cast<const uint32_t *>(bytes);
    signed char *arr = const_cast<signed char *>(
        reinterpret_cast<const signed char *>(bytes + sizeof(uint32_t)));
    _engine.DispatchCommand(param, 0, 0, 0, 0, arrSize, arr);
  } else {
    _engine.DispatchCommand(param, 0, 0, 0, 0, (uint32_t)data.length,
                            (signed char *)data.bytes);
  }
  os_unfair_lock_unlock(&_lock);
}

- (void)setSamplingRate:(uint32_t)rate {
  os_unfair_lock_lock(&_lock);
  _engine.SetSamplingRate(rate);
  os_unfair_lock_unlock(&_lock);
}

- (uint32_t)getSamplingRate {
  os_unfair_lock_lock(&_lock);
  uint32_t rate = _engine.GetSamplingRate();
  os_unfair_lock_unlock(&_lock);
  return rate;
}

- (uint64_t)getProcessTimeMs {
  os_unfair_lock_lock(&_lock);
  uint64_t t = _engine.GetProcessTimeMs();
  os_unfair_lock_unlock(&_lock);
  return t;
}

- (uint32_t)getConvolverKernelID {
  os_unfair_lock_lock(&_lock);
  uint32_t kid = _engine.GetConvolverKernelID();
  os_unfair_lock_unlock(&_lock);
  return kid;
}

@end
