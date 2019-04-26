os_dir?=..


local/default: all
	ls

%: ${CURDIR}/index.mk ${os_dir}
	make -C ${os_dir} -f $< $@

clean: ..
	rm -f ${<}/.config

rebuild: clean default
	ls
