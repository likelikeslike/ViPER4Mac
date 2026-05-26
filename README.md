# ViPER4Mac

System-wide audio effects processor for macOS, ported from ViPER4Android.

ViPER4Mac brings the legendary ViPER audio processing engine to macOS. It captures all
system audio using Apple's Core Audio Tap API, applies ViPER effects in real-time, and
routes the processed audio to the output device. No virtual audio driver or kernel
extension required.

## Features

- FIR Equalizer with 10, 15, 25, or 31 bands
- Dynamic EQ with up to 8 bands (Peak, Low Shelf, High Shelf filters)
- ViPER Bass enhancement (Natural, Pure Bass, Subwoofer modes)
- ViPER Bass Mono
- Psychoacoustic Bass with harmonic generation
- ViPER Clarity (Natural, OZone, XHiFi modes)
- Tube Simulator and AnalogX warmth processing
- Spectrum Extension with bark frequency and exciter control
- Field Surround with stereo widening, mid image, and depth control
- Differential Surround with LP crossover
- Stereo Imager with 3-band width control
- Headphone Surround+ (VHE) for virtual surround on headphones
- Reverberation with full room modeling
- FET Compressor with auto knee/gain/attack/release
- Multiband Compressor (5 bands)
- Playback Gain Control (AGC)
- LUFS Targeting with speed control
- Auditory System Protection (CURe crossfeed)
- Speaker Optimization (speaker mode)
- ViPER-DDC device correction (.vdc profiles)
- Convolver with WAV/IRS impulse responses
- Dynamic System headphone compensation with user presets

## Requirements

- macOS 15 (Sequoia) or later with Apple Silicon

## Compatibility

ViPER4Mac uses Apple's Process Tap API and conflicts with audio utilities that
install their own Core Audio drivers (e.g. Rogue Amoeba SoundSource, Boom 3D,
Loopback). Running ViPER4Mac alongside such tools causes audible crackling
because both products write audio to the same output device simultaneously.
Use one or the other, not both.

## Installation

### Pre-built release

Download the latest release from the [Releases page](https://github.com/likelikeslike/ViPER4Mac/releases). Copy the `ViPER4Mac.app` bundle to your Applications folder and launch it.

### From source

Xcode with command line tools required.

```bash
git clone --recursive https://github.com/likelikeslike/ViPER4Mac.git && cd ViPER4Mac
make install
```

On first launch, macOS will ask to allow system audio recording. Click Allow.

## Usage

Click the "V" icon in the menu bar to open the control panel. Toggle effects on or off
globally, or expand individual sections to fine-tune parameters. The app automatically
detects whether you're using headphones or speakers and switches profiles accordingly.
You can also override this manually if you have multiple output devices.

Each device maintains its own independent settings.

### Presets and Profiles

User data lives in `~/Library/Application Support/ViPER4Mac/`. You can import and export:

- **Full presets** (JSON) capturing all effect settings at once
- **DDC profiles** (.vdc) for device-specific frequency correction
- **Convolver kernels** (WAV/IRS) for impulse response processing
- **EQ presets** and **Dynamic System presets** individually

The app supports Launch at Login and remembers all settings between sessions.

## Uninstall

```bash
make uninstall
# or manually:
osascript -e 'tell application "ViPER4Mac" to quit'
sleep 1
sudo rm -rf /Applications/ViPER4Mac.app
rm -rf ~/Library/Application\ Support/ViPER4Mac
rm -rf ~/Library/Logs/ViPER4Mac
```

## Credits

- **ViPER4Android** by Zhuhang and ViPER520
- **ViPERDSP** reverse engineering by Martmists, Iscle, and likelikeslike ([ViPERDSP](https://github.com/likelikeslike/ViPERDSP))
