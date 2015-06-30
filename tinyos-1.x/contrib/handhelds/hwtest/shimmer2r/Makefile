######################################################################
#
#  Top-level make file.  Just build all of the apps
#
######################################################################

# handle documentation generation
DOCS := $(filter docs, $(MAKECMDGOALS))
MAKECMDGOALS := $(filter-out docs, $(MAKECMDGOALS))
ifeq ($(DOCS)_x, docs_x)
MAKEFLAGS += -k
endif

# catch-all rule - pass targets on to the lower level
%:
	@for d in `ls`; do \
	if [ -f $$d/Makefile ]; then \
		echo "$$d...."; \
		$(MAKE) -C $$d $@ $(DOCS) \
		|| case "$(MAKEFLAGS)" in *k*) fail=yes;; *) exit 1;; esac; \
	fi; \
	done; test -z "$$fail"

all:

docs:
	@echo ""
 
