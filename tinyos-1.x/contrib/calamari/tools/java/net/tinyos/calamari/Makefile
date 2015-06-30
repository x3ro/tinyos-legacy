TOS = $(shell ncc -print-tosdir)
APP = ../../../../..
PACKAGE = net.tinyos.calamari
MIG = mig java
JAVA = javac

# List of message classes to build
MSGS = TransmitModeMsg.java TimestampMsg.java ChirpMsg.java SensitivityMsg.java EstReportMsg.java DiagMsg.java TransmitCommandMsg.java OuterStruct.java
INITIAL_TARGETS = $(MSGS)
OTHER_CLEAN = cleanmig

include $(TOS)/../tools/java/Makefile.include

TransmitModeMsg.java:
	$(MIG) -java-classname=$(PACKAGE).TransmitModeMsg $(APP)/include/Omnisound.h TransmitModeMsg >$@
	$(JAVAC) $@

TimestampMsg.java:
	$(MIG) -java-classname=$(PACKAGE).TimestampMsg $(APP)/include/Omnisound.h TimestampMsg >$@
	$(JAVAC) $@

ChirpMsg.java:
	$(MIG) -java-classname=$(PACKAGE).ChirpMsg $(APP)/include/Omnisound.h ChirpMsg >$@
	$(JAVAC) $@

SensitivityMsg.java:
	$(MIG) -java-classname=$(PACKAGE).SensitivityMsg $(APP)/include/Omnisound.h SensitivityMsg >$@
	$(JAVAC) $@

EstReportMsg.java:
	$(MIG) -java-classname=$(PACKAGE).EstReportMsg $(APP)/include/Omnisound.h EstReportMsg >$@
	$(JAVAC) $@

DiagMsg.java:
	$(MIG) -java-classname=$(PACKAGE).DiagMsg $(APP)/include/Omnisound.h DiagMsg >$@
	$(JAVAC) $@

TransmitCommandMsg.java:
	$(MIG) -java-classname=$(PACKAGE).TransmitCommandMsg $(APP)/include/Omnisound.h TransmitCommandMsg >$@
	$(JAVAC) $@

OuterStruct.java:
	$(MIG) -java-classname=$(PACKAGE).OuterStruct $(APP)/include/test.h outerStruct >$@
	$(JAVAC) $@

cleanmig:
	rm -f $(MSGS)

