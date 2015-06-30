# Top-level Makefile for platform/sim

ROOT = .
# NAMES = tossim tossim/util
NAMES = tossim/util
SOURCES = $(NAMES:%=src/%)
TESTS = $(NAMES:tossim%=test/tossim_test%)
DOCUMENTS = doc

# SUBDIRS = foo bar baz
# 
# subdirs: $(SUBDIRS)
# 
# $(SUBDIRS):
#         $(MAKE) -C $@

.PHONY: clean src src_clean test test_clean runtest docs docs_clean
.PHONY: $(SOURCES) $(TESTS) $(DOCUMENTS)

all: src test docs

clean:  src_clean test_clean docs_clean

src:
	$(MAKE) $(SOURCES) COMMAND=all

src_clean:
	$(MAKE) $(SOURCES) COMMAND=clean

test:
	$(MAKE) $(TESTS) COMMAND=all

test_clean:
	$(MAKE) $(TESTS) COMMAND=clean

runtest:
	$(MAKE) $(TESTS) COMMAND=runtest

docs:
	$(MAKE) $(DOCUMENTS) COMMAND=all

docs_clean:
	$(MAKE) $(DOCUMENTS) COMMAND=all

$(SOURCES) $(TESTS) $(DOCUMENTS):
	$(MAKE) -C $@ $(COMMAND)
