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

default: rule/default
	@echo "# $@: $^"

MAKE+=V=1
os_dir?=${CURDIR}
build_dir?=${os_dir}
tmp_dir?=${CURDIR}/tmp

apps_url?=https://bitbucket.org/nuttx/apps
apps_dir?=apps
#{
machine_family?=esp32
machine?=${machine_family}-core
export machine

base_config?=nsh
image_type?=nsh
base_defconfig?=${build_dir}/configs/${machine}/${base_config}/defconfig
defconfig?=${build_dir}/configs/${machine}/${image_type}/defconfig
config_type?=${machine}/${image_type}
export config_type

image?=nuttx
elf_image?=${image}
deploy_image?=${image}._deploy.bin
cfg=${build_dir}/configs/${machine_family}/scripts/${machine_family}.cfg

# board usb
tty?=/dev/ttyUSB0
tty_rate?=115200
vendor_id?=10c4
product_id?=ea60
udev?=/etc/udev/rules.d/99-usb-${vendor_id}-${product_id}.rules
config?=${os_dir}/.config
#TODO
openocd?=openocd
#openocd=/usr/bin/openocd -d
#openocd=openocd -d

cfg?=${build_dir}/configs/${machine}/tools/openocd/
#TODO
cfg=${build_dir}/configs/${machine_family}/scripts/${machine_family}.cfg

#{ toolchain
toolchain_url?=https://github.com/espressif/crosstool-NG
toolchain_type?=xtensa-esp32-elf
toolchain_branch?=xtensa-1.22.x
crosstool?=${tmp_dir}/crosstool-NG
configure?=${os_dir}/tools/configure.sh
XPATH?=${crosstool}/builds/${toolchain_type}/bin
CROSSCOMPILE?=${XPATH}/${toolchain_type}-
CC=${CROSSCOMPILE}gcc

export XPATH
export PATH := ${XPATH}:${PATH}
#} toolchain

rule/default: prep rule/all
	@echo "# $@: $^"

clean:
	rm -fv *~

cleanall: clean
	-rm -v ${deploy_image} ${image}
	-rm -rf tmp

distclean: cleanall
	rm -f ${config}

help: Makefile
	@echo "# Available rules:"
	@grep -o "^[^ \t]*:" $<

check: ${CC}
	${CC} --version

${os_dir}/Make.defs: config
#	ls $@ || make config
	ls $@

prep: ${os_dir}/Make.defs ${CC}
	@echo "# $@: $^"

rule/%: ${config} prep
	cd ${<D} && PATH=${PATH}:${XPATH} ${MAKE} ${@F}

${config}: ${configure} ${defconfig} ${apps_dir} #Makefile
	@echo "# Configure: ${config_type}"
	cd ${<D} && ./${<F} -a ${apps_dir} ${config_type}
	ls -l "$@"

#TODO
config: ${config}
	ls -l ${config}
	echo 'CONFIG_ESP32CORE_RUN_IRAM=y' >> $<

menuconfig: ${config}
	${MAKE} -C ${os_dir} $@


${elf_image}: ${config}
	${MAKE}
	ls -l ${@}

#${elf_image}: rule/all
#	@echo "# $@: $^"

#${image}: ${elf_image}
#	ls $@ || ${MAKE} build
#	ls -l "$@"

build: rule/all
	ls -l "$@"

esptool_url?=https://github.com/espressif/esptool
esptool?=esptool/esptool.py
#esptool?=esptool
deploy_tty_rate?=921600
deploy_freq=40m
deploy_capacity=2MB
deploy_mode?=dio
boot_offset?=0x1000

${deploy_image}: ${elf_image} ${esptool}
	${esptool} --chip esp32 elf2image -o ${deploy_image} ${elf_image}
	ls -l ${@}

deploy: ${deploy_image}
	grep CONFIG_ESP32CORE_RUN_IRAM=y .config
	${esptool} --chip esp32 \
 --port ${tty} --baud ${deploy_tty_rate} \
 write_flash \
 -z --flash_mode ${deploy_mode} --flash_freq ${deploy_freq} --flash_size ${deploy_capacity} \
 ${boot_offset} ${deploy_image}

done/deploy: tmp/done/deploy.tmp

tmp/done/deploy.tmp: deploy
	mkdir -p ${@D}
	touch $@
deploy/help: openocd/help
	@echo "# $@: $^"

# http://openocd.org/doc-release/html/index.html#toc-Reset-Configuration-1
reset: openocd/help
	@echo "press micro switch called EN"

partition: ${partition}
	cat "$<"

configure: ${build_dir}/configs
	ls $<

setup: setup/debian
	@echo "TODO: support other OS"

setup/debian: /etc/debian_version
	sudo apt-get update -y
	sudo apt-get install -y git gperf libncurses5-dev flex bison
	sudo apt-get install -y openocd libusb-1.0
	sudo apt-get install -y genromfs time
	sudo apt-get install -y texinfo

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

configs: build/configs/${machine}/
	ls $<
#

${signer}: ${sdk}

defconfig: ${defconfig} ${base_defconfig}
	ls -l $^

${defconfig}: ${base_defconfig}
	@mkdir -p ${@D}
	cp -rfv ${<D}/* ${@D}

all: ${image} ${config} ${defconfig} ${base_defconfig}
	ls -l $^

commit:
	git add build/configs/${machine}/${image_type} ||:
	git commit -sam "WIP: ${image_type}" ||:

save:
	mkdir -p build/configs/${config_type}/
	cp -av ${config} ${defconfig}
	${MAKE} commit

save/%: save
	mkdir -p build/configs/${machine}/${@F}
	cp -rf build/configs/${config_type}/* build/configs/${machine}/${base_config}/
	cp ${config} build/configs/${machine}/${@F}/defconfig
	git add build/configs/${machine}/${@F} ||:
	${MAKE} commit

demo: commit cleanall menuconfig all deploy console
	${MAKE} commit

run: commit done/deploy console
	${MAKE} commit

diff: ${defconfig}
	meld $^ ${config}

diff/%: build/configs/${machine} ${config}
	meld $</${@F}/defconfig ${config}

devel: ${defconfig} build/configs/${machine}/devel/defconfig
	meld $^

devel/rm:
	rm -rf build/configs/${machine}/devel
	${MAKE} commit

build/configs/${config_type}/.config:
	exit 1
	cp -a os/.config $@

env:
	@echo "image_type=${image_type}"

#{ apps
${apps_dir}:
	mkdir -p ${@D} && cd ${@D} && git clone --depth 1 ${apps_url} "${@F}"

apps_dir: ${apps_dir}
	ls $<
#} apps

#{ toolchain

${crosstool}/%:
	mkdir -p ${@D} && cd ${@D} && \
 git clone --depth 1 -b ${toolchain_branch} ${toolchain_url} .

${crosstool}/configure: ${crosstool}/bootstrap
	cd ${<D} && ./${<F}

${crosstool}/Makefile: ${crosstool}/configure
	cd ${<D} && ./${<F} --prefix="${CURDIR}"

${crosstool}/ct-ng: ${crosstool}/Makefile
	${MAKE} -C ${<D} install MAKELEVEL=0

${CC}: ${crosstool}/ct-ng
	cd ${<D} \
&& ./ct-ng xtensa-esp32-elf \
&& ./ct-ng build \
&& chmod -R u+w builds/xtensa-esp32-elf

#} toolchain

${esptool}:
	git clone --depth 1 ${esptool_url}
