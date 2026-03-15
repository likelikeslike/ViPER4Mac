#include <CoreAudio/AudioServerPlugIn.h>
#include <aspl/Device.hpp>
#include <aspl/Driver.hpp>
#include <aspl/MuteControl.hpp>
#include <aspl/Plugin.hpp>
#include <aspl/Stream.hpp>
#include <aspl/VolumeControl.hpp>
#include <atomic>
#include <cstdio>
#include <fcntl.h>
#include <sys/mman.h>
#include <sys/stat.h>
#include <unistd.h>

#include "TPCircularBuffer.h"
#include "ViPERSharedRing.h"

static const char *kViPERLogDir = "/Library/Logs/ViPER4Mac";
static const char *kViPERLogFile = "/Library/Logs/ViPER4Mac/driver.log";

static FILE *openDriverLog() {
    mkdir(kViPERLogDir, 0755);
    return fopen(kViPERLogFile, "a");
}

static const char *kViPERDeviceUID = "ViPER4Mac_VirtualDevice";
static const char *kViPERDeviceName = "ViPER4Mac";
static const UInt32 kViPERChannelCount = 2;
static const UInt32 kViPERDefaultSampleRate = 48000;
static const UInt32 kViPERRingBufferFrames = 16384;

class ViPERIOHandler : public aspl::IORequestHandler {
public:
    ViPERIOHandler() {
        TPCircularBufferInit(
            &ringBuffer_, kViPERRingBufferFrames * kViPERChannelCount * sizeof(Float32)
        );
        initSharedMemory();
    }

    ~ViPERIOHandler() override {
        TPCircularBufferCleanup(&ringBuffer_);
        if (sharedRing_) {
            munmap(sharedRing_, VIPER_SHM_SIZE);
        }
    }

    void OnProcessMixedOutput(
        const std::shared_ptr<aspl::Stream> &stream,
        Float64 zeroTimestamp,
        Float64 timestamp,
        Float32 *frames,
        UInt32 frameCount,
        UInt32 channelCount
    ) override {}

    void OnWriteMixedOutput(
        const std::shared_ptr<aspl::Stream> &stream,
        Float64 zeroTimestamp,
        Float64 timestamp,
        const void *bytes,
        UInt32 bytesCount
    ) override {
        TPCircularBufferProduceBytes(&ringBuffer_, bytes, bytesCount);

        if (sharedRing_) {
            const float *src = static_cast<const float *>(bytes);
            uint32_t sampleCount = bytesCount / sizeof(float);
            uint64_t wp =
                atomic_load_explicit(&sharedRing_->writePos, memory_order_relaxed);
            uint64_t rp =
                atomic_load_explicit(&sharedRing_->readPos, memory_order_acquire);
            uint64_t used = (wp >= rp) ? (wp - rp) : (VIPER_SHM_RING_SAMPLES - rp + wp);
            uint64_t available = VIPER_SHM_RING_SAMPLES - used - 1;
            if (sampleCount <= available) {
                for (uint32_t i = 0; i < sampleCount; i++) {
                    sharedRing_->samples[(wp + i) % VIPER_SHM_RING_SAMPLES] = src[i];
                }
                atomic_store_explicit(
                    &sharedRing_->writePos,
                    (wp + sampleCount) % VIPER_SHM_RING_SAMPLES,
                    memory_order_release
                );
            }
        }

        writeCount_++;
        if (writeCount_ % 5000 == 1) {
            const float *src = static_cast<const float *>(bytes);
            uint32_t sampleCount = bytesCount / sizeof(float);
            float maxVal = 0.0f;
            for (uint32_t i = 0; i < sampleCount; i++) {
                float v = src[i] < 0 ? -src[i] : src[i];
                if (v > maxVal) maxVal = v;
            }
            FILE *f = openDriverLog();
            if (f) {
                fprintf(
                    f,
                    "WriteMixed: count=%llu bytes=%u shm=%s max=%.6f\n",
                    writeCount_.load(),
                    bytesCount,
                    sharedRing_ ? "yes" : "no",
                    maxVal
                );
                fclose(f);
            }
        }
    }

    void OnReadClientInput(
        const std::shared_ptr<aspl::Client> &client,
        const std::shared_ptr<aspl::Stream> &stream,
        Float64 zeroTimestamp,
        Float64 timestamp,
        void *bytes,
        UInt32 bytesCount
    ) override {
        uint32_t availableBytes = 0;
        void *head = TPCircularBufferTail(&ringBuffer_, &availableBytes);

        if (head && availableBytes >= bytesCount) {
            memcpy(bytes, head, bytesCount);
            TPCircularBufferConsume(&ringBuffer_, bytesCount);
        } else {
            memset(bytes, 0, bytesCount);
        }
    }

private:
    TPCircularBuffer ringBuffer_;
    std::atomic<uint64_t> writeCount_{0};
    ViPERSharedRing *sharedRing_ = nullptr;

    void initSharedMemory() {
        int fd = open(VIPER_SHM_FILE, O_CREAT | O_RDWR, 0666);
        if (fd < 0) {
            FILE *f = openDriverLog();
            if (f) {
                fprintf(f, "open shm file failed: %d\n", errno);
                fclose(f);
            }
            return;
        }
        fchmod(fd, 0666);
        if (ftruncate(fd, VIPER_SHM_SIZE) != 0) {
            close(fd);
            return;
        }
        void *ptr =
            mmap(nullptr, VIPER_SHM_SIZE, PROT_READ | PROT_WRITE, MAP_SHARED, fd, 0);
        close(fd);
        if (ptr == MAP_FAILED) {
            FILE *f = openDriverLog();
            if (f) {
                fprintf(f, "mmap failed\n");
                fclose(f);
            }
            return;
        }
        sharedRing_ = static_cast<ViPERSharedRing *>(ptr);
        atomic_store_explicit(&sharedRing_->writePos, 0, memory_order_relaxed);
        atomic_store_explicit(&sharedRing_->readPos, 0, memory_order_relaxed);
        memset(sharedRing_->samples, 0, sizeof(sharedRing_->samples));

        FILE *f = openDriverLog();
        if (f) {
            fprintf(
                f, "SharedRing initialized, size=%lu\n", (unsigned long) VIPER_SHM_SIZE
            );
            fclose(f);
        }
    }
};

class ViPERDevice : public aspl::Device {
public:
    ViPERDevice(
        std::shared_ptr<aspl::Context> context, const aspl::DeviceParameters &params
    ) :
        aspl::Device(std::move(context), params) {}

    UInt32 GetTransportType() const override { return kAudioDeviceTransportTypeBuiltIn; }

    OSStatus StartIOImpl(UInt32 clientID, UInt32 startCount) override {
        FILE *f = openDriverLog();
        if (f) {
            fprintf(f, "StartIO: clientID=%u startCount=%u\n", clientID, startCount);
            fclose(f);
        }
        return aspl::Device::StartIOImpl(clientID, startCount);
    }

    OSStatus StopIOImpl(UInt32 clientID, UInt32 startCount) override {
        FILE *f = openDriverLog();
        if (f) {
            fprintf(f, "StopIO: clientID=%u startCount=%u\n", clientID, startCount);
            fclose(f);
        }
        return aspl::Device::StopIOImpl(clientID, startCount);
    }

    OSStatus WillDoIOOperationImpl(
        UInt32 clientID, UInt32 operationID, Boolean *outWillDo, Boolean *outWillDoInPlace
    ) override {
        switch (operationID) {
            case kAudioServerPlugInIOOperationReadInput:
            case kAudioServerPlugInIOOperationMixOutput:
            case kAudioServerPlugInIOOperationWriteMix:
                *outWillDo = true;
                *outWillDoInPlace = true;
                break;
            default:
                break;
        }
        return kAudioHardwareNoError;
    }
};

static std::shared_ptr<aspl::Driver> s_driver;

extern "C" void *ViPER4Mac_Create(CFAllocatorRef allocator, CFUUIDRef typeUUID) {
    (void) allocator;
    FILE *f = openDriverLog();
    if (f) {
        fprintf(f, "ViPER4Mac_Create called\n");
        fclose(f);
    }

    if (!CFEqual(typeUUID, kAudioServerPlugInTypeUUID)) {
        return nullptr;
    }

    auto context = std::make_shared<aspl::Context>();

    auto ioHandler = std::make_shared<ViPERIOHandler>();

    aspl::DeviceParameters deviceParams;
    deviceParams.Name = kViPERDeviceName;
    deviceParams.DeviceUID = kViPERDeviceUID;
    deviceParams.SampleRate = kViPERDefaultSampleRate;
    deviceParams.ChannelCount = kViPERChannelCount;
    deviceParams.CanBeDefault = true;
    deviceParams.CanBeDefaultForSystemSounds = true;
    deviceParams.Latency = 0;
    deviceParams.SafetyOffset = 0;
    deviceParams.ZeroTimeStampPeriod = kViPERRingBufferFrames;
    deviceParams.ClockIsStable = true;

    auto device = std::make_shared<ViPERDevice>(context, deviceParams);
    device->SetIOHandler(ioHandler);

    AudioStreamBasicDescription format = {};
    format.mSampleRate = kViPERDefaultSampleRate;
    format.mFormatID = kAudioFormatLinearPCM;
    format.mFormatFlags = kAudioFormatFlagIsFloat | kAudioFormatFlagsNativeEndian
                          | kAudioFormatFlagIsPacked;
    format.mBitsPerChannel = 32;
    format.mChannelsPerFrame = kViPERChannelCount;
    format.mBytesPerFrame = kViPERChannelCount * sizeof(Float32);
    format.mFramesPerPacket = 1;
    format.mBytesPerPacket = kViPERChannelCount * sizeof(Float32);

    aspl::StreamParameters outputStreamParams;
    outputStreamParams.Direction = aspl::Direction::Output;
    outputStreamParams.Format = format;
    device->AddStreamAsync(outputStreamParams);

    aspl::StreamParameters inputStreamParams;
    inputStreamParams.Direction = aspl::Direction::Input;
    inputStreamParams.Format = format;
    device->AddStreamAsync(inputStreamParams);

    device->AddVolumeControlAsync(kAudioObjectPropertyScopeOutput);
    device->AddMuteControlAsync(kAudioObjectPropertyScopeOutput);
    auto plugin = std::make_shared<aspl::Plugin>(context);
    plugin->AddDevice(device);

    s_driver = std::make_shared<aspl::Driver>(context, plugin);

    FILE *f2 = openDriverLog();
    if (f2) {
        fprintf(f2, "ViPER4Mac_Create completed, device=%u\n", device->GetID());
        fprintf(
            f2,
            "  inputStreams=%u outputStreams=%u\n",
            device->GetStreamCount(aspl::Direction::Input),
            device->GetStreamCount(aspl::Direction::Output)
        );
        fclose(f2);
    }

    return s_driver->GetReference();
}
