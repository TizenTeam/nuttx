#!/usr/bin/make -f
# -*- makefile -*-
# ex: set tabstop=4 noexpandtab:
# -*- coding: utf-8 -*-
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
#
# 1. Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in
#    the documentation and/or other materials provided with the
#    distribution.
# 3. Neither the name NuttX nor the names of its contributors may be
#    used to endorse or promote products derived from this software
#    without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
# "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
# LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
# FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
# COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
# INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
# BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS
# OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED
# AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
# LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN
# ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.
#
############################################################################

#{esp
chip?=esp32
platform?=${chip}
machine_family?=esp32
machine?=${machine_family}-core
export machine
base_image_type?=nsh

baudrate?=115200
vendor_id?=10c4
product_id?=ea60

#TODO
openocd?=openocd
#openocd=/usr/bin/openocd -d
#openocd=openocd -d


#{esp
esptool_url?=https://github.com/espressif/esptool
esptool_dir?=${extra_dir}/esptool
esptool?=${esptool_dir}/esptool.py
#esptool?=esptool
deploy_tty_rate?=921600
deploy_freq=40m
deploy_capacity=2MB
deploy_mode?=dio
boot_offset?=0x1000
partitions_offset?=0x8000
os_offset?=0x10000
all+=${bootloader_image} ${partition_image}
cfg=${configs_dir}/${machine_family}/scripts/${machine_family}.cfg
tty?=/dev/ttyUSB0
tty_rate?=115200
udev?=/etc/udev/rules.d/99-usb-${vendor_id}-${product_id}.rules
#}esp

#{ toolchain
toolchain_url?=https://github.com/espressif/crosstool-NG
toolchain_type?=xtensa-${chip}-elf
toolchain_branch?=xtensa-1.22.x
crosstool_dir?=${extra_dir}/crosstool-NG
XPATH?=${crosstool_dir}/builds/${toolchain_type}/bin
CROSSCOMPILE?=${XPATH}/${toolchain_type}-
CC=${CROSSCOMPILE}gcc
PATH:=${XPATH}:${PATH}
export PATH
prep_files+=${CC}
#} toolchain


esp_idf_url?=https://github.com/espressif/esp-idf
esp_idf_dir?=${extra_dir}/esp-idf
esp_app_dir?=${esp_idf_dir}/examples/get-started/hello_world

#bootloader_image?=${esptool_dir}/test/elf2image/esp32-bootloader.elf
#partitions_image?=${esptool_dir}/test/images/partitions_singleapp.bin

bootloader_image?=${esp_app_dir}/build/bootloader/bootloader.bin
partitions_image?=${esp_app_dir}/build/partitions_singleapp.bin

cu?=/usr/bin/cu

#} generic
