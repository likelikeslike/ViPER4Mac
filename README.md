# ViPER4Mac

System-wide audio effects processor for macOS, ported from ViPER4Android.

ViPER4Mac brings the legendary ViPER audio processing engine to macOS. It captures all
system audio, applies ViPER effects in real-time, and routes the result to the output device.

## Features

- FIR Equalizer with 10, 15, 25, or 31 bands
- ViPER Bass enhancement (Natural, Pure Bass, Subwoofer modes)
- ViPER Clarity (Natural, OZone, XHiFi modes)
- Tube Simulator and AnalogX warmth processing
- Spectrum Extension
- Field Surround with stereo widening, mid image, and depth control
- Differential Surround
- Headphone Surround+ (VHE) for virtual surround on headphones
- Reverberation with full room modeling
- FET Compressor
- Playback Gain Control (AGC)
- Auditory System Protection (CURe crossfeed)
- Speaker Optimization (speaker mode)
- ViPER-DDC device correction (.vdc profiles)
- Convolver with WAV/IRS impulse responses
- Dynamic System headphone compensation

## Requirements

- macOS Sequoia or later with Apple Silicon
- Tested on macos Sequoia 15.7.4

## Installation

### Package Installer

Download the `ViPER4Mac.pkg` installer from the [Releases]() page and run it. Follow the prompts to complete installation.

### From source

- Xcode with command line tools required

```bash
git clone --recursive https://github.com/likelikeslike/ViPER4Mac.git
make install
```

## Usage

ViPER4Mac works by installing a virtual audio driver that captures system audio, applies effects in real-time, and routes it to your the device.

Click the "V" icon in the menu bar to open the control panel. Toggle effects on or off
globally, or expand individual sections to fine-tune parameters. The app automatically
detects whether you're using headphones or speakers and switches profiles accordingly.
You can also override this manually if you have multiple output devices.

Each mode (headphone/speaker) maintains its own independent settings.

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
sudo rm -rf /Library/Audio/Plug-Ins/HAL/ViPER4Mac.driver
rm -rf ~/Library/Application\ Support/ViPER4Mac
rm ~/Library/Logs/ViPER4Mac/viper.log
sudo killall coreaudiod
```

## Credits

- **ViPER4Android** by Zhuhang and ViPER520
- **ViPERDSP** reverse engineering by Martmists, Iscel, and likelikeslike ([ViPERDSP](https://github.com/likelikeslike/ViPERDSP))
- **libASPL** by [gavv](https://github.com/gavv/libASPL)
- **TPCircularBuffer** by [Michael Tyson](https://github.com/michaeltyson/TPCircularBuffer)
