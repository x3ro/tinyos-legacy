DIRS = $(patsubst ./%,%,$(dir $(shell find . -name Makefile | sed 's/^..//')))

%: dirs
	@:

dirs: FORCE
	for dir in $(DIRS); do (cd $$dir; echo; make $(MAKECMDGOALS)); done

.PHONY: FORCE

