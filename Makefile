PROJECT    := ViPER4Mac.xcodeproj
CONFIG     := Release
ARCH       := arm64
BUILD_DIR  := build/$(CONFIG)

APP_NAME   := ViPER4Mac.app
DRIVER_NAME := ViPER4Mac.driver

APP_SRC    := $(BUILD_DIR)/$(APP_NAME)
DRIVER_SRC := $(BUILD_DIR)/$(DRIVER_NAME)

APP_DST    := /Applications/$(APP_NAME)
DRIVER_DST := /Library/Audio/Plug-Ins/HAL/$(DRIVER_NAME)

PKG_DIR    := build/pkg
PKG_ROOT   := $(PKG_DIR)/root
PKG_OUT    := build/ViPER4Mac.pkg
VERSION    := 1.0.0
DRIVER_VERSION := 1.0.0

.PHONY: all app driver build install uninstall clean package

all: build

app:
	xcodebuild -project $(PROJECT) -target ViPER4Mac -configuration $(CONFIG) \
		build MARKETING_VERSION=$(VERSION) ONLY_ACTIVE_ARCH=YES ARCHS=$(ARCH) BUILD_DIR=$(CURDIR)/build

driver:
	xcodebuild -project $(PROJECT) -target ViPERDriver -configuration $(CONFIG) \
		build MARKETING_VERSION=$(DRIVER_VERSION) ONLY_ACTIVE_ARCH=YES ARCHS=$(ARCH) BUILD_DIR=$(CURDIR)/build

build: app driver

install: build
	@echo "Installing ViPER4Mac (requires sudo)..."
	-osascript -e 'tell application "ViPER4Mac" to quit' 2>/dev/null
	@sleep 1
	sudo killall coreaudiod 2>/dev/null || true
	@sleep 1
	sudo rm -rf $(DRIVER_DST)
	sudo rm -rf $(APP_DST)
	sudo cp -R $(DRIVER_SRC) $(DRIVER_DST)
	sudo cp -R $(APP_SRC) $(APP_DST)
	@echo "Waiting for coreaudiod to restart..."
	@sleep 3
	open $(APP_DST)
	@echo "Done."

uninstall:
	@echo "Uninstalling ViPER4Mac (requires sudo)..."
	-osascript -e 'tell application "ViPER4Mac" to quit' 2>/dev/null
	@sleep 1
	-sudo rm -rf $(APP_DST)
	-sudo rm -rf $(DRIVER_DST)
	sudo killall coreaudiod 2>/dev/null || true
	@echo "Done."

clean:
	rm -rf build

package: build
	@echo "Building installer package..."
	rm -rf $(PKG_DIR)
	mkdir -p $(PKG_ROOT)/Applications
	mkdir -p $(PKG_ROOT)/Library/Audio/Plug-Ins/HAL
	mkdir -p $(PKG_DIR)/scripts
	cp -R $(APP_SRC) $(PKG_ROOT)/Applications/
	cp -R $(DRIVER_SRC) "$(PKG_ROOT)/Library/Audio/Plug-Ins/HAL/"
	cp installer/preinstall $(PKG_DIR)/scripts/preinstall
	cp installer/postinstall $(PKG_DIR)/scripts/postinstall
	chmod +x $(PKG_DIR)/scripts/preinstall $(PKG_DIR)/scripts/postinstall
	pkgbuild \
		--root $(PKG_ROOT) \
		--scripts $(PKG_DIR)/scripts \
		--identifier com.viper4mac.pkg \
		--version $(VERSION) \
		--install-location / \
		$(PKG_DIR)/ViPER4Mac-component.pkg
	productbuild \
		--distribution installer/Distribution.xml \
		--package-path $(PKG_DIR) \
		--resources installer \
		$(PKG_OUT)
	@echo "Installer created: $(PKG_OUT)"
