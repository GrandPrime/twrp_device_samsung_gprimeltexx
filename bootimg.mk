MKBOOTIMG := device/samsung/gprimeltexx/mkbootimg
TWRP_VERSION := $(shell cat bootable/recovery/variables.h | grep "define TW_MAIN_VERSION_STR" | cut -d\" -f2)
TWRP_NAME := recovery-TWRP-$(TWRP_VERSION)-gprimeltexx-$(shell date +%Y-%m-%d-%H.%M.%S)

BUILT_RAMDISK_CPIO := $(PRODUCT_OUT)/ramdisk-recovery.cpio
COMPRESS_COMMAND := xz --format=lzma --lzma1=dict=16MiB -9

ifdef TARGET_PREBUILT_DTB
	BOARD_MKBOOTIMG_ARGS += --dt $(TARGET_PREBUILT_DTB)
endif

INSTALLED_RECOVERYIMAGE_TARGET := $(PRODUCT_OUT)/recovery.img
$(INSTALLED_RECOVERYIMAGE_TARGET): $(recovery_ramdisk)
	@echo "------- Compressing recovery ramdisk -------"
	$(hide) $(COMPRESS_COMMAND) "$(BUILT_RAMDISK_CPIO)"
	@echo "------- Making recovery image -------"
	$(hide) $(MKBOOTIMG) \
		--kernel $(TARGET_PREBUILT_KERNEL) \
		--ramdisk $(BUILT_RAMDISK_CPIO).lzma \
		--cmdline "$(BOARD_KERNEL_CMDLINE)" \
		--base $(BOARD_KERNEL_BASE) \
		--pagesize $(BOARD_KERNEL_PAGESIZE) \
		$(BOARD_MKBOOTIMG_ARGS) \
		-o $(INSTALLED_RECOVERYIMAGE_TARGET)
	$(hide) cp $(PRODUCT_OUT)/recovery.img $(PRODUCT_OUT)/$(TWRP_NAME).img
	@echo "------- Made recovery image: $@ -------"
	$(hide) echo -n "SEANDROIDENFORCE" >> $(INSTALLED_RECOVERYIMAGE_TARGET)
	@echo "------- Lied about SEAndroid state to Samsung bootloader -------"
	$(hide) cd $(PRODUCT_OUT) && tar -H ustar -c $(shell basename $@) > $(TWRP_NAME).tar
	$(hide) cd $(PRODUCT_OUT) && md5sum -t $(TWRP_NAME).tar >> $(TWRP_NAME).tar
	$(hide) mv $(PRODUCT_OUT)/$(TWRP_NAME).tar $(PRODUCT_OUT)/$(TWRP_NAME).tar.md5
	@echo "------- Made flashable image: $(PRODUCT_OUT)/$(TWRP_NAME).tar.md5 -------"
