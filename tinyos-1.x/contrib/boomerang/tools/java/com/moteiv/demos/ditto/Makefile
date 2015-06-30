TOS=$(shell ncc -print-tosdir)
MOTEIV_DIR ?= ../../../../../../
CYG_MOTEIV_DIR = $(shell if [ -f /bin/cygwin1.dll ]; then cygpath -u "$(MOTEIV_DIR)"; else echo "$(MOTEIV_DIR)"; fi)
PACKAGE=com.moteiv.demos.ditto
MIG=mig java -target=telosb -I%T/lib/CC2420Radio -DTOSH_DATA_LENGTH=48

JAVACLASSES = Ditto.java
MSGS = PlayRecordDataMsg.java PlayRecordRequestMsg.java

all: compile
	@:

$(MSGS): $(CYG_MOTEIV_DIR)/apps/invent/Ditto/Ditto.h
	$(MIG) -java-classname=$(PACKAGE).$(@:%.java=%) $< $(@:%.java=%) -o $@

compile: $(MSGS)
	javac $(MSGS) $(JAVACLASSES)

clean:
	rm -f $(MSGS) $(MSGS:%.java=%.class) $(JAVACLASSES:%.java=%.class)

