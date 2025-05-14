ARCH := riscv
CROSS_COMPILE := riscv64-linux-gnu-

UBOOT_DIR := $(CURDIR)/u-boot
SPL_TOOL_DIR := $(CURDIR)/tools/spl_tool
OPENSBI_DIR := $(CURDIR)/opensbi
UBOOT_ITS_DIR := $(CURDIR)/tools/uboot_its
GENIMAGE_DIR := $(CURDIR)/genimage

all: build genimage

build: uboot spl_tool opensbi fw_payload

uboot:
	$(MAKE) -C ${UBOOT_DIR} starfive_visionfive2_defconfig
	$(MAKE) -C ${UBOOT_DIR} ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE}

spl_tool:
	$(MAKE) -C ${SPL_TOOL_DIR}
	${SPL_TOOL_DIR}/spl_tool -c -f ${UBOOT_DIR}/spl/u-boot-spl.bin
	cp ${UBOOT_DIR}/spl/u-boot-spl.bin.normal.out .

.PHONY: opensbi
opensbi:
	$(MAKE) -C ${OPENSBI_DIR} ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} \
		PLATFORM=generic FW_PAYLOAD_PATH=${UBOOT_DIR}/u-boot.bin \
		FW_FDT_PATH=${UBOOT_DIR}/arch/riscv/dts/starfive_visionfive2.dtb \
		FW_TEXT_START=0x40000000

fw_payload:
	cp ${OPENSBI_DIR}/build/platform/generic/firmware/fw_payload.bin ${UBOOT_ITS_DIR}
	cd ${UBOOT_ITS_DIR} && \
	${UBOOT_DIR}/tools/mkimage -f ${UBOOT_ITS_DIR}/visionfive2-uboot-fit-image.its \
		-A riscv -O u-boot -T firmware visionfive2_fw_payload.img
	rm ${UBOOT_ITS_DIR}/fw_payload.bin
	mv ${UBOOT_ITS_DIR}/visionfive2_fw_payload.img .

genimage:
	genimage --config genimage-vf2.cfg --inputpath . --outputpath .

clean:
	$(MAKE) -C ${UBOOT_DIR} distclean
	$(MAKE) -C ${SPL_TOOL_DIR} clean
	$(MAKE) -C ${OPENSBI_DIR} distclean
	rm -f u-boot-spl.bin.normal.out
	rm -f visionfive2_fw_payload.img
	rm -f starfive-visionfive2-vfat.part
	rm -f sdcard.img
	rm -f u-boot.cfg.tmp
