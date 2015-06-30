# Run make in any subdirectory that contains a Makefile

# com.moteiv.trawler depends on net.tinyos.message being compiled first, so
# have Find print the Makefiles in net before those in com.

DIRS = $(dir $(shell find net com -name Makefile))

all clean: FORCE
	for dir in $(DIRS); do (cd $$dir; echo; make $@); done

.PHONY: FORCE

