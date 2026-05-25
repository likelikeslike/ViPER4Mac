#import "ViPERBridge.h"
#include "viper/ViPER.h"
#include <atomic>
#include <cstring>
#include <vector>

#ifndef VIPER_VERSION_CODE
#define VIPER_VERSION_CODE 0
#endif
#ifndef VIPER_VERSION_NAME
#define VIPER_VERSION_NAME "0.0.0"
#endif

struct ViPERCommand {
  enum Type : uint8_t { SET_PARAM, SET_PARAM_DATA, SET_SAMPLE_RATE };
  Type type;
  int param;
  int v1, v2, v3, v4;
  uint32_t arrSize;
  uint8_t data[8192];
  uint32_t sampleRate;
};

static constexpr int kCommandQueueSize = 64;
static constexpr size_t kMaxFrameCount = 4096;

@implementation ViPERBridge {
  ViPER _engine;
  std::vector<float> _processBuffer;

  ViPERCommand _commandQueue[kCommandQueueSize];
  std::atomic<uint32_t> _cmdHead;
  std::atomic<uint32_t> _cmdTail;
}

- (instancetype)init {
  self = [super init];
  if (self) {
    _processBuffer.resize(kMaxFrameCount * 2);
    _cmdHead.store(0, std::memory_order_relaxed);
    _cmdTail.store(0, std::memory_order_relaxed);
  }
  return self;
}

- (void)enqueueCommand:(const ViPERCommand &)cmd {
  uint32_t head = _cmdHead.load(std::memory_order_relaxed);
  uint32_t tail = _cmdTail.load(std::memory_order_acquire);
  uint32_t nextHead = (head + 1) % kCommandQueueSize;
  if (nextHead == tail) {
    return;
  }
  _commandQueue[head] = cmd;
  _cmdHead.store(nextHead, std::memory_order_release);
}

- (void)drainCommands {
  uint32_t tail = _cmdTail.load(std::memory_order_relaxed);
  uint32_t head = _cmdHead.load(std::memory_order_acquire);
  while (tail != head) {
    const auto &cmd = _commandQueue[tail];
    switch (cmd.type) {
    case ViPERCommand::SET_PARAM:
      _engine.DispatchCommand(cmd.param, cmd.v1, cmd.v2, cmd.v3, cmd.v4, 0, nullptr);
      break;
    case ViPERCommand::SET_PARAM_DATA:
      _engine.DispatchCommand(
          cmd.param, cmd.v1, cmd.v2, cmd.v3, cmd.v4, cmd.arrSize,
          const_cast<signed char *>(reinterpret_cast<const signed char *>(cmd.data)));
      break;
    case ViPERCommand::SET_SAMPLE_RATE:
      _engine.SetSamplingRate(cmd.sampleRate);
      _engine.resetAllEffects();
      break;
    }
    tail = (tail + 1) % kCommandQueueSize;
  }
  _cmdTail.store(tail, std::memory_order_release);
}

- (void)processAudio:(float *)buffer frameCount:(uint32_t)frameCount {
  [self drainCommands];

  uint32_t sampleCount = frameCount * 2;
  if (_processBuffer.size() < sampleCount) {
    _processBuffer.resize(sampleCount);
  }
  memcpy(_processBuffer.data(), buffer, sampleCount * sizeof(float));
  _engine.process(_processBuffer, frameCount);
  memcpy(buffer, _processBuffer.data(), sampleCount * sizeof(float));
}

- (void)setParameter:(int)param
              value1:(int)v1
              value2:(int)v2
              value3:(int)v3
              value4:(int)v4 {
  ViPERCommand cmd{};
  cmd.type = ViPERCommand::SET_PARAM;
  cmd.param = param;
  cmd.v1 = v1;
  cmd.v2 = v2;
  cmd.v3 = v3;
  cmd.v4 = v4;
  [self enqueueCommand:cmd];
}

- (void)setParameterWithData:(int)param data:(NSData *)data {
  ViPERCommand cmd{};
  cmd.type = ViPERCommand::SET_PARAM_DATA;
  cmd.param = param;

  if (data.length == 8192) {
    const uint8_t *bytes = static_cast<const uint8_t *>(data.bytes);
    cmd.v1 = *reinterpret_cast<const int *>(bytes);
    cmd.arrSize = *reinterpret_cast<const uint32_t *>(bytes + sizeof(int));
    size_t payloadOffset = sizeof(int) + sizeof(uint32_t);
    size_t copyLen = data.length - payloadOffset;
    if (copyLen > sizeof(cmd.data)) copyLen = sizeof(cmd.data);
    memcpy(cmd.data, bytes + payloadOffset, copyLen);
  } else if (data.length == 256 || data.length == 1024) {
    const uint8_t *bytes = static_cast<const uint8_t *>(data.bytes);
    cmd.arrSize = *reinterpret_cast<const uint32_t *>(bytes);
    size_t payloadOffset = sizeof(uint32_t);
    size_t copyLen = data.length - payloadOffset;
    if (copyLen > sizeof(cmd.data)) copyLen = sizeof(cmd.data);
    memcpy(cmd.data, bytes + payloadOffset, copyLen);
  } else {
    cmd.arrSize = (uint32_t)data.length;
    size_t copyLen = data.length;
    if (copyLen > sizeof(cmd.data)) copyLen = sizeof(cmd.data);
    memcpy(cmd.data, data.bytes, copyLen);
  }

  [self enqueueCommand:cmd];
}

- (void)setSamplingRate:(uint32_t)rate {
  ViPERCommand cmd{};
  cmd.type = ViPERCommand::SET_SAMPLE_RATE;
  cmd.sampleRate = rate;
  [self enqueueCommand:cmd];
}

- (uint32_t)getSamplingRate {
  return _engine.GetSamplingRate();
}

- (uint64_t)getProcessedFrames {
  return _engine.GetProcessedFrames();
}

- (NSString *)getVersionName {
  return @VIPER_VERSION_NAME;
}

- (uint32_t)getVersionCode {
  return VIPER_VERSION_CODE;
}

@end
