os?=nuttx
#XPATH=${HOME}/mnt/gcc-arm-none-eabi-4_9-2015q3/bin
#export XPATH
#PATH=${XPATH}:${PATH} 
machine?=lm3s6965evb
export machine
config?=qemu-i486/nsh
export config
qemu?=qemu-system-arm
CONFIG_APPS_DIR=apps
export CONFIG_APPS_DIR
V=1 
VERBOSE=1
make=${MAKE} CONFIG_APPS_DIR=${CONFIG_APPS_DIR}
apps_dir?=apps
apps_url?=https://bitbucket.org/nuttx/apps

default: os/all

os/%: .config
	${make} -C ${<D} ${@F}

.config: tools/configure.sh configs/${config} ${apps_dir}
	ls ${@} || { cd ${<D} && ./${<F} -a ${apps_dir} ${config}; }

config: 
	${make} menuconfig

run: output/bin/nuttx
	ls -l ${<D}
	${qemu} -M ${machine} -kernel $< -nographic

build/output/bin/${os}: os/all

stop:
	killall ${qemu}

distclean:
	rm -f os/.config

${apps_dir}:
	git clone ${apps_url} "$@"


build: .config
	${make}
