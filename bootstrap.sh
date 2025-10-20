#!/bin/sh

# Install base
apk update
apk add openrc
rc-update add devfs boot
rc-update add procfs boot
rc-update add sysfs boot
rc-update add networking default
rc-update add local default

# Install TTY
apk add agetty

# Setting up shell
apk add shadow
apk add bash bash-completion
chsh -s /bin/bash
echo -e "luckfox\nluckfox" | passwd
apk del -r shadow

# Install SSH
apk add openssh
rc-update add sshd default
chown 0:0 /var/empty

# Extra stuff
apk add mtd-utils-ubi
apk add bottom
apk add neofetch
apk add e2fsprogs-extra

# Install NTPD
apk add openntpd
rc-update add openntpd default

# install htop
apk add htop

# install dialog for lockfox-config
apk add dialog
apk add dtc
apk add i2c-tools
apk add git
apk add python3
apk add nano
apk add py3-pip

# python3 venv, install packages
mkdir -p /opt/veloxsensor3
python3 -m venv /opt/veloxsensor3
source /opt/veloxsensor3/bin/activate

echo "show disk usage and list /extrootfs"
df -h
ls -alh /opt

pip install smbus2
pip install w1thermsensor[async]
pip install w1thermsensor
pip install pymodbus[serial]
deactivate

echo "show disk usage and list /extrootfs"
df -h
ls -alh /opt

# Clear apk cache
rm -rf /var/cache/apk/*

# Packaging rootfs
for d in bin etc lib sbin usr var opt; do tar c "$d" | tar x -C /extrootfs; done
for dir in dev proc root run sys oem userdata; do mkdir /extrootfs/${dir}; done
