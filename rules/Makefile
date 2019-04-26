os_dir?=${CURDIR}/..

local/default: all
	ls

%: ${os_dir}/rules/index.mk
	cd ${os_dir} && make -f $< $@

${os_dir}/rules/index.mk:
	ls $@
clean: ..
	rm -f ${<}/.config

rebuild: clean default
	ls
