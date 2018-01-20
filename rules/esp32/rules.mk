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
machine_family?=esp32
machine?=${machine_family}-core
export machine
# TODO: adapt with yours (ie: 0403:6015)
vendor_id?=10c4
product_id?=ea60

#TODO
openocd?=openocd
#openocd=/usr/bin/openocd -d
#openocd=openocd -d


#{esp
esptool_url?=https://github.com/espressif/esptool
esptool_dir?=esptool
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
crosstool?=${tmp_dir}/crosstool-NG
XPATH?=${crosstool}/builds/${toolchain_type}/bin
CROSSCOMPILE?=${XPATH}/${toolchain_type}-
CC=${CROSSCOMPILE}gcc
#} toolchain

esp32/help: ${CC}
	${CC} --version

esp32/setup/debian:
	sudo apt-get install -y python-serial usbutils
	@echo "log: TODO: check if ${vendor_id}:${product_id} present"
	-lsusb

#{ toolchain

${crosstool_dir}:
	mkdir -p ${@D}
	git clone --depth 1 -b ${toolchain_branch} ${toolchain_url} $@

${crosstool_dir}/%: ${crosstool_dir}
	ls $@

${crosstool_dir}/configure: ${crosstool_dir}/bootstrap
	cd ${<D} && ./${<F}

${crosstool_dir}/Makefile: ${crosstool_dir}/configure
	cd ${<D} && ./${<F} --prefix="${CURDIR}"

${crosstool_dir}/ct-ng: ${crosstool_dir}/Makefile
	${MAKE} -C ${<D} install MAKELEVEL=0

${CC}: ${crosstool_dir}/ct-ng
	cd ${<D} \
&& ./ct-ng xtensa-esp32-elf \
&& ./ct-ng build \
&& chmod -R u+w builds/xtensa-esp32-elf
#} toolchain


#{ deploy
${deploy_image}: ${elf_image} ${esptool}
	${esptool} --chip ${chip} elf2image -o ${deploy_image} ${elf_image}
	ls -l ${@}

deploy/boot: ${deploy_image} ${tty}
	grep CONFIG_ESP32CORE_RUN_IRAM=y .config
	${esptool} --chip ${chip} \
 --port ${tty} --baud ${deploy_tty_rate} \
 write_flash \
 -z --flash_mode ${deploy_mode} --flash_freq ${deploy_freq} --flash_size ${deploy_capacity} \
 ${boot_offset} ${deploy_image}


deploy/partitions: ${deploy_image} ${bootloader_image} ${partition_image} ${tty}
	@ls -l $^
	${esptool} --chip ${chip} \
 --port ${tty} --baud ${deploy_tty_rate} \
 write_flash \
 ${boot_offset} ${bootloader_image} \
 ${partitions_offset} ${partitions_image} \
 ${os_offset} ${deploy_image}

deploy: deploy/partitions
	@echo "log: Success: $@: $^"

done/deploy: tmp/done/deploy.tmp
	ls $^

tmp/done/deploy.tmp: deploy
	mkdir -p ${@D}
	touch $@

deploy/help: openocd/help
	@echo "# $@: $^"

# http://openocd.org/doc-release/html/index.html#toc-Reset-Configuration-1
reset: openocd/help
	@echo "press micro switch called EN"

${esptool_dir}:
	mkdir -p ${@D}
	git clone --recursive --depth 1 ${esptool_url} $@
	ls $@

${esptool_dir}/%: ${esptool_dir}
	ls -l $@

${esptool}: ${esptool_dir}
	$@ -h

${esp_idf_dir}:
	mkdir -p ${@D}
	git clone --recursive --depth 1 ${esp_idf_url} $@
	ls $@


#TODO: skipmenuconfi
#/tmp/nuttx/tmp/esp-idf/examples/get-started/hello_world/sdkconfig

${esp_idf_dir}/%: ${esp_idf_dir}
	ls -l $@

${esp_app}: ${esp_idf_dir}

	ls $@

${bootloader_image}: ${esp_app_dir} ${esp_idf_dir}
	${MAKE} -C ${<} IDF_PATH=${esp_idf_dir} defconfig
	${MAKE} -C ${<} IDF_PATH=${esp_idf_dir}
	ls $@

#} esp

# config: ${config}
# 	ls -l ${config}
# 	echo 'CONFIG_ESP32CORE_RUN_IRAM=y' >> $<


setup: 
	ls /etc/debian_version && ${make} setup/debian && exit 0
	@echo "TODO: support other OS"


console: ${tty}
	@echo "Hit reset button next to module"
	screen $< ${tty_rate}

cu?=/usr/bin/cu

test: ${tty}
	sudo sync
	sudo stty -F ${<} raw speed ${tty_rate}
	sudo stty -F ${<}
	xterm -e "cat ${<}" &
	sleep 1
	"$(shell sleep 3)cat /proc/version$(shell sleep 3)\n" | sudo tee -a ${tty}

todo/test: ${tty}
	@echo "$(shell sleep 3)cat /proc/version$(shell sleep 3)\n~." \
| ${cu} -s ${tty_rate} -l ${tty}

${cu}: /etc/debian_release
	sudo apt-get install cu

${tty}:
	ls /dev/ttyUSB*

${udev}:
	lsusb | grep "${vendor_id}:${product_id}"
	@echo "SUBSYSTEMS==\"usb\",ATTRS{idVendor}==\"${vendor_id}\",ATTRS{idProduct}==\"${product_id}\",MODE=\"0666\" RUN+=\"/sbin/modprobe ftdi_sio RUN+=\"/bin/sh -c 'echo ${vendor_id} ${product_id} > /sys/bus/usb-serial/drivers/ftdi_sio/new_id' " | sudo tee $@

udev: ${udev}
	cat $<
#EOF




esp32/run: deploy console
	@echo "TODO"



#} generic
