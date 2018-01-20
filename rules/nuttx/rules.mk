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

nuttx/help: ${CC}
	echo ${CC}
	${CC} --version

${apps_dir}:
	mkdir -p ${@D} && cd ${@D} && git clone --depth 1 ${apps_url} "${@F}"

${apps_dir}/%: ${apps_dir}
	ls -l $@

${config}: ${configure} ${defconfig} ${apps_dir}/README.txt
	@echo "log: Is ${@} existing?"
	-ls -l ${config}
	@echo "# Configure: ${config_type}"
	cd ${<D} && ./${<F} -a ${apps_dir} ${config_type}
	ls -l "$@"

# all: ${image} ${config} ${defconfig} ${base_defconfig}
# 	ls -l $^

# #TODO

# ${os_dir}/Make.defs: config
# #	ls $@ || make config
# 	ls $@

# prep: ${os_dir}/Make.defs ${CC}
# 	@echo "# $@: $^"

# rule/%: ${config} prep
# 	cd ${<D} && PATH=${PATH}:${XPATH} ${MAKE} ${@F}

# #TODO
# config: ${config}
# 	ls -l ${config}
# 	echo 'CONFIG_ESP32CORE_RUN_IRAM=y' >> $<

# menuconfig: ${config}
# 	${MAKE} -C ${os_dir} $@


# ${elf_image}: ${config}
# 	${MAKE}
# 	ls -l ${@}

# #${elf_image}: rule/all
# #	@echo "# $@: $^"

# #${image}: ${elf_image}
# #	ls $@ || ${MAKE} build
# #	ls -l "$@"

# tmp/done/deploy.tmp: deploy
# 	mkdir -p ${@D}
# 	touch $@

# deploy/help: openocd/help
# 	@echo "# $@: $^"

# partition: ${partition}
# 	cat "$<"

# configure: ${build_dir}/configs
# 	ls $<

# setup: setup/debian
# 	@echo "TODO: support other OS"

# setup/debian: /etc/debian_version
# 	sudo apt-get update -y
# 	sudo apt-get install -y git gperf libncurses5-dev flex bison
# 	sudo apt-get install -y openocd libusb-1.0
# 	sudo apt-get install -y genromfs time
# 	sudo apt-get install -y texinfo

# configs: build/configs/${machine}/
# 	ls $<
# #

# defconfig: ${defconfig} ${base_defconfig}
# 	ls -l $^

# ${defconfig}: ${base_defconfig}
# 	@mkdir -p ${@D}
# 	cp -rfv ${<D}/* ${@D}


# commit:
# 	git add build/configs/${machine}/${image_type} ||:
# 	git commit -sam "WIP: ${image_type}" ||:

# save:
# 	mkdir -p build/configs/${config_type}/
# 	cp -av ${config} ${defconfig}
# 	${MAKE} commit

# save/%: save
# 	mkdir -p build/configs/${machine}/${@F}
# 	cp -rf build/configs/${config_type}/* build/configs/${machine}/${base_config}/
# 	cp ${config} build/configs/${machine}/${@F}/defconfig
# 	git add build/configs/${machine}/${@F} ||:
# 	${MAKE} commit

# demo: commit cleanall menuconfig all deploy console
# 	${MAKE} commit

# run: commit done/deploy console
# 	${MAKE} commit

# diff: ${defconfig}
# 	meld $^ ${config}

# diff/%: build/configs/${machine} ${config}
# 	meld $</${@F}/defconfig ${config}

# devel: ${defconfig} build/configs/${machine}/devel/defconfig
# 	meld $^

# devel/rm:
# 	rm -rf build/configs/${machine}/devel
# 	${MAKE} commit

# build/configs/${config_type}/.config:
# 	exit 1
# 	cp -a os/.config $@

# env:
# 	@echo "image_type=${image_type}"

