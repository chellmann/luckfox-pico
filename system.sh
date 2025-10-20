#!/bin/bash

ROOTFS_NAME="rootfs-alpine.tar.gz"
DEVICE_NAME="pico-mini-b"

while getopts ":f:d:" opt; do
  case ${opt} in
    f) ROOTFS_NAME="${OPTARG}" ;;
    d) DEVICE_NAME="${OPTARG}" ;;
    ?)
      echo "Invalid option: -${OPTARG}."
      exit 1
      ;;
  esac
done


rm -rf sdk/sysdrv/custom_rootfs/
mkdir -p sdk/sysdrv/custom_rootfs/
cp "$ROOTFS_NAME" sdk/sysdrv/custom_rootfs/

ROOTFS_NAME=$(basename "$ROOTFS_NAME")

pushd sdk || exit

pushd tools/linux/toolchain/arm-rockchip830-linux-uclibcgnueabihf/ || exit
source env_install_toolchain.sh
popd || exit

rm -rf .BoardConfig.mk
case $DEVICE_NAME in
  pico-plus-flash) ln -s project/cfg/BoardConfig_IPC/BoardConfig-SPI_NAND-Buildroot-RV1103_Luckfox_Pico_Plus-IPC.mk .BoardConfig.mk ;;
  *)
    echo "Invalid device: ${DEVICE_NAME}."
    exit 1
    ;;
esac

#echo "$DEVICE_ID" | ./build.sh lunch
echo "export RK_CUSTOM_ROOTFS=../sysdrv/custom_rootfs/$ROOTFS_NAME" >> .BoardConfig.mk
echo "export RK_BOOTARGS_CMA_SIZE=\"1M\"" >> .BoardConfig.mk

#change size on SD
if echo "$DEVICE_NAME" | grep -q "\-sd"; then
	echo "export RK_PARTITION_CMD_IN_ENV=\"32K(env),512K@32K(idblock),256K(uboot),32M(boot),512M(oem),256M(userdata),30G(rootfs)\"" >> .BoardConfig.mk
fi

#echo "was hier los?"
#pwd
#ls -alh

# i2c enable
#sed -i '/&i2c3 {/,/};/s/status = "disabled"/status = "okay"/g' sysdrv/tools/board/kernel/rv1103g-luckfox-pico-plus.dts
#cat sysdrv/tools/board/kernel/rv1103g-luckfox-pico-plus.dts
#ls -alh
#ls -alh sysdrv/tools/board/kernel
rm sysdrv/tools/board/kernel/rv1103g-luckfox-pico-plus.dts
cp ../rv1103g-luckfox-pico-plus.dts sysdrv/tools/board/kernel/rv1103g-luckfox-pico-plus.dts

# 1-wire
echo "CONFIG_W1=y" >> sysdrv/tools/board/kernel/luckfox_rv1106_linux_defconfig
echo "CONFIG_W1_MASTER_GPIO=y" >> sysdrv/tools/board/kernel/luckfox_rv1106_linux_defconfig
echo "CONFIG_W1_SLAVE_THERM=y" >> sysdrv/tools/board/kernel/luckfox_rv1106_linux_defconfig


#cat .BoardConfig.mk

# build sysdrv - rootfs
./build.sh uboot
./build.sh kernel
./build.sh driver
./build.sh env
#./build.sh app
# package firmware
./build.sh firmware
./build.sh save

popd || exit

rm -rf output
mkdir -p output
cp sdk/output/image/* "output/"
