#---------------------------------------------------------------------------------
.SUFFIXES:
#---------------------------------------------------------------------------------
define n


endef

ifeq ($(strip $(DEVKITARM)),)
$(error "Please set DEVKITARM in your environment. export DEVKITARM=<path to>devkitARM")
endif

ifeq ($(strip $(LOVEPOTION_3DS)),)

export ERR_MSG := \
$nPlease set LOVEPOTION_3DS in your environment.\
$nThis should be the path to your Love Potion projects.\
$nDo *NOT* save the *.elf file anywhere else.\
$nexport LOVEPOTION_3DS=<path to>/LovePotion.elf
$(error $(ERR_MSG))
endif

UNAME := $(shell uname)
ifeq ($(UNAME), Linux)
	makerom    := $(CURDIR)/data/tools/linux/makerom
	bannertool := $(CURDIR)/data/tools/linux/bannertool
else ifeq ($(UNAME), Darwin)
	makerom    := $(CURDIR)/data/tools/osx/makerom
	bannertool := $(CURDIR)/data/tools/osx/bannertool
else
	makerom    := $(CURDIR)/data/tools/windows/makerom.exe
	bannertool := $(CURDIR)/data/tools/windows/bannertool.exe
endif

TOPDIR ?= $(CURDIR)
include $(DEVKITARM)/3ds_rules

#---------------------------------------------------------------------------------
# TARGET is the name of the output files
# BUILD is the directory where object files & intermediate files will be placed
# ROMFS is the directory containing your LOVE game
#
# APP_TITLE is the name of the app stored in the .3dsx file (Optional)
# APP_AUTHOR is the author of the app stored in the .3dsx file (Optional)
# APP_VERSION is the version of the app stored in the .3dsx file (Optional)
# APP_TITLEID is the titleID of the app stored in the .3dsx file (Optional)
# APP_DESCRIPTION is the description of the application
#
# ICON is the filename of the icon (.png), relative to the project folder.
#---------------------------------------------------------------------------------
TARGET          := $(notdir $(CURDIR))
BUILD           := $(TOPDIR)

ROMFS           := game/

APP_TITLE       := DDEM-LOVE
APP_AUTHOR      := GameVasion
APP_TITLEID     := 0xDDFC
APP_VERSION     := 1.1
APP_DESCRIPTION := An unofficial DDEM port for the 3DS!

ICON            := data/icon.png

#---------------------------------------------------------------------------------
# cia variables
#
# BANNER_IMAGE: the banner must be a 256x128px png
# BANNER_AUDIO: audio must be wav or ogg and ~3 seconds long maximum
# UNIQUE_ID   : a hex number, must be unique so it does not overwrite other apps
#               keep the leading 0x part, only change the last four numbers
# PRODUCT_CODE: change the last four digits, must also be unique (?)
#---------------------------------------------------------------------------------

RSF_PATH        := data/info.rsf
BANNER_AUDIO    := data/audio.wav
BANNER_IMAGE    := data/banner.png

ICON_FLAGS      := nosavebackups,visible
UNIQUE_ID       := 0xDDEC # must be unique!
PRODUCT_CODE    := CTR-H-DDEM # change this too

#---------------------------------------------------------------------------------
# build options
#---------------------------------------------------------------------------------

export OUTPUT    :=    $(TARGET)
export TOPDIR    :=    $(CURDIR)

ifeq ($(strip $(ICON)),)
	icons := $(wildcard *.png)
	ifneq (,$(findstring $(TARGET).png,$(icons)))
		export APP_ICON := $(TOPDIR)/$(TARGET).png
	else
		ifneq (,$(findstring icon.png,$(icons)))
			export APP_ICON := $(TOPDIR)/icon.png
		endif
	endif
else
	export APP_ICON := $(TOPDIR)/$(ICON)
endif

#---------------------------------------------------------------------------------
# main targets
#---------------------------------------------------------------------------------

all: $(OUTPUT).smdh $(OUTPUT).3dsx

$(OUTPUT).smdh:
	@echo "Building smdh.."
	@smdhtool --create "$(APP_TITLE)" "$(APP_DESCRIPTION)" "$(APP_AUTHOR)" "$(APP_ICON)" $@

$(OUTPUT).3dsx:
	@echo "Building 3dsx.."
	@3dsxtool $(LOVEPOTION_3DS) $@ --smdh=$(OUTPUT).smdh --romfs=$(ROMFS)

#---------------------------------------------------------------------------------
# cia targets
#
# note: to build as a cia, download bannertool and makerom
# add the respective OS binary to your path:
#
# export makerom=<path/to/makerom>
# export bannertool=<path/to/bannertool>
#---------------------------------------------------------------------------------
cia: banner icon
	@$(makerom) -f cia \
	-o $(OUTPUT).cia \
	-target t \
	-exefslogo \
	-elf $(LOVEPOTION_3DS) \
	-rsf "$(RSF_PATH)" \
	-banner "$(BUILD)/banner.bnr" \
	-icon "$(BUILD)/icon.icn" \
	-DAPP_TITLE="$(APP_TITLE)" \
	-DAPP_PRODUCT_CODE="$(PRODUCT_CODE)" \
	-DAPP_UNIQUE_ID="$(UNIQUE_ID)" \
	-DAPP_ROMFS="$(ROMFS)"

banner:
	@$(bannertool) makebanner \
	-i "$(BANNER_IMAGE)" \
	-a "$(BANNER_AUDIO)" \
	-o "$(BUILD)/banner.bnr"

icon:
	@$(bannertool) makesmdh \
	-s "$(APP_TITLE)" \
	-l "$(APP_DESCRIPTION)" \
	-p "$(APP_AUTHOR)" \
	-i "$(APP_ICON)" \
	-f "$(ICON_FLAGS)" \
	-o "$(BUILD)/icon.icn"
