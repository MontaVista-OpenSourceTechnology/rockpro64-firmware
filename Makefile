
all: binaries

clean: arm-tf-clean u-boot-clean bin-clean

ROOT ?= $(shell pwd)

BINARIES_PATH ?= $(ROOT)/bin

DEBUG = 0

CROSS_COMPILE ?= aarch64-linux-gnu-

################################################################################
# ARM Trusted Firmware
################################################################################
TF_A_EXPORTS ?= CROSS_COMPILE="$(CROSS_COMPILE)"

TF_A_PATH = $(ROOT)/atf

TF_A_DEBUG ?= $(DEBUG)
ifeq ($(TF_A_DEBUG),0)
TF_A_LOGLVL ?= 30
TF_A_OUT = $(TF_A_PATH)/build/rk3399/release
else
TF_A_LOGLVL ?= 50
TF_A_OUT = $(TF_A_PATH)/build/rk3399/debug
endif

TF_A_FLAGS ?= \
        PLAT=rk3399 \
        DEBUG=$(TF_A_DEBUG) \
        LOG_LEVEL=$(TF_A_LOGLVL)

        #BL32=$(OPTEE_OS_HEADER_V2_BIN) \
        #BL32_EXTRA1=$(OPTEE_OS_PAGER_V2_BIN) \
        #BL32_EXTRA2=$(OPTEE_OS_PAGEABLE_V2_BIN) \
        #ARM_ARCH_MAJOR=8 \
        #ARM_TSP_RAM_LOCATION=tdram \
        #BL32_RAM_LOCATION=tdram \
        #AARCH64_SP=optee \
        #BL31=${TF_A_OUT}/bl31/bl31.elf \
        #BL33=$(ROOT)/u-boot/u-boot.bin \
        #ARCH=aarch64

arm-tf:
	$(TF_A_EXPORTS) $(MAKE) -C atf $(TF_A_FLAGS) bl31

arm-tf-clean:
	$(TF_A_EXPORTS) $(MAKE) -C atf $(TF_A_FLAGS) realclean

################################################################################
# u-boot
################################################################################

U-BOOT_PATH = $(ROOT)/u-boot
U-BOOT_BUILD ?= $(U-BOOT_PATH)/build

U-BOOT_DEFCONFIG_FILES := \
	$(U-BOOT_PATH)/configs/rockpro64-rk3399_defconfig \
        $(ROOT)/RockPro64.config

U-BOOT_EXPORTS ?= \
        CROSS_COMPILE="$(CROSS_COMPILE)" \
        BL31=${TF_A_OUT}/bl31/bl31.elf \
        ARCH=arm64

u-boot: arm-tf
	if test ! -e $(U-BOOT_BUILD); then mkdir $(U-BOOT_BUILD); fi
	if test ! -e $(U-BOOT_BUILD)/.config; then \
	  cd $(U-BOOT_PATH) && \
	       scripts/kconfig/merge_config.sh -O $(U-BOOT_BUILD) \
		$(U-BOOT_DEFCONFIG_FILES); \
	fi
	$(U-BOOT_EXPORTS) $(MAKE) -C $(U-BOOT_PATH) O=$(U-BOOT_BUILD) all

u-boot-clean:
	rm -rf $(U-BOOT_BUILD)

################################################################################
# u-boot
################################################################################

BIN_DIR = $(ROOT)/bin
TPLSPL = $(U-BOOT_BUILD)/tpl/u-boot-tpl.bin:$(U-BOOT_BUILD)/spl/u-boot-spl.bin

# u-boot SPI offset is set to 0x60000 in the rockpro64 dtb file.
binaries: u-boot
	if test ! -e $(BIN_DIR); then mkdir $(BIN_DIR); fi
	cp $(U-BOOT_BUILD)/idbloader.img $(U-BOOT_BUILD)/u-boot.itb $(BIN_DIR)
	$(U-BOOT_BUILD)/tools/mkimage -n rk3399 -T rkspi \
		-d $(TPLSPL) $(BIN_DIR)/u-boot-spi.tmp1 && \
	   dd if=$(BIN_DIR)/u-boot-spi.tmp1 of=$(BIN_DIR)/u-boot-spi.tmp2 \
		bs=384K conv=sync && \
	   cat $(BIN_DIR)/u-boot-spi.tmp2 $(U-BOOT_BUILD)/u-boot.itb \
		>$(BIN_DIR)/u-boot-spi.img
	@echo
	@echo "******************************************************"
	@echo "To install on an SD card, do:"
	@echo "  sudo dd if=bin/idbloader.img of=/dev/mmcblkX seek=64"
	@echo "  sudo dd if=bin/u-boot.itb of=/dev/mmcblkX seek=16384"
	@echo "  sync"
	@echo "to an mmc card, replacing X with your specific card."
	@echo "For spi, "
	@echo "  sf update 0x800800 0 0x400000"

bin-clean:
	rm -rf bin
