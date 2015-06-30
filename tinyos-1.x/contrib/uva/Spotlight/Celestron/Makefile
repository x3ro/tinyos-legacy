TOS = $(shell ncc -print-tosdir)
MIG = mig java
COMPILER = javac
JAVA-EXEC = java

# List of message classes to build
LIST = SyncMsg.java ReportMsg.java ReportAckMsg.java ConfigMsg.java Other

INITIAL_TARGETS = $(LIST)
OTHER_CLEAN = cleaning

include Makefile.include

SyncMsg.java:
	$(MIG) -java-classname=SyncMsg ../BASE/BASE.h SyncMsg -o $@
	$(JAVAC) $@

ReportAckMsg.java:
	$(MIG) -java-classname=ReportAckMsg ../Common/common.h ReportAckMsg -o $@
	$(JAVAC) $@

ReportMsg.java:
	$(MIG) -java-classname=ReportMsg ../Common/common.h ReportMsg -o $@
	$(JAVAC) $@

ConfigMsg.java:
	$(MIG) -java-classname=ConfigMsg ../Common/common.h  ConfigMsg -o $@
	$(JAVAC) $@

cleaning:
	rm -f ./packet/*.class
	rm -f *.class


Other:
	@echo "compile GUI code"
	$(COMPILER) packet/*.java
	$(COMPILER) CelestronGUI.java 

run:
	$(JAVA-EXEC) CelestronGUI &
