local/default: rebuild
	ls

%:
	make -C .. -f build.mk $@

clean: ..
	rm -f ${<}/.config

rebuild: clean default
	ls

