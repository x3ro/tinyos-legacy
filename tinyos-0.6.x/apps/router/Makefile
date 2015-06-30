
ifeq (,$(TOS_VERBOSE_MAKE))
SILENT = -s
endif


all clean rene pc:
	@for d in `ls`; do \
		if [ -f $$d/Makefile ]; then \
			echo "$(MAKE) $@ in $$d"; \
			$(MAKE) $(SILENT) -C $$d $@ || exit 1; \
		fi; \
	done



