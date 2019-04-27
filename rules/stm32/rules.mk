# TODO: keep private in ~/
dev_id?=066EFF323535474B43065221
dev_file?=/dev/disk/by-id/usb-MBED_microcontroller_${dev_id}-0:0
dev_link?=/tmp/${CURDIR}/deploy
#USER?=$(shell echo ${USER})
nuttx_deploy_dir?=/media/${USER}/NODE_F767ZI1
nuttx_dur?=.
nuttx_image_file?=nuttx.bin
monitor_rate?=115200
monitor_file?=$(shell ls /dev/ttyACM* | sort | tail -n1)

stm32/setup/debian:
	sudo apt-get install -y stlink-tools

todo/stm32/deploy: ${nuttx_image_file}
	-lsusb # 0483:374b STMicroelectronics ST-LINK/V2.1 (Nucleo-F103RB)
#	/usr/bin/st-flash write ${<} ${deploy_address}
	cp $< /media/philippe/NODE_F767ZI1/
# 0483:374b STMicroelectronics ST-LINK/V2.1 (Nucleo-F103RB)

${dev_link}/DETAILS.TXT:
	ls -l ${dev_file}
	sudo umount -f ${dev_file} ${deploy_dir} || echo $$?
	udisksctl mount -b ${dev_file} ||:
	ln -fs ${deploy_dir} ${@D}

${nuttx_deploy_dir}: ${dev_link}/DETAILS.TXT
	ls ${@}

${nuttx_deploy_dir}/nuttx.bin: ${nuttx_image_file}  ${nuttx_deploy_dir}
	cp -av $< $@
	sleep 6
	sudo sync
#	ls ${@D}

stm32/deploy: ${nuttx_deploy_dir}/nuttx.bin
	sudo sync

${monitor_file}:
	lsusb
	ls $@

monitor: ${monitor_file} # deploy
	echo "# TODO: use C-a k to quit"
	sleep 1
	${sudo} screen $< ${monitor_rate}
