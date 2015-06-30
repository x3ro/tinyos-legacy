PACKAGE = net.tinyos.mgmtquery
OTHER_CLEAN = cleanmig
LIB = $(TOSDIR)/../beta/SystemCore/MgmtQuery

MIG = mig -I$(LIB) java
NCG = ncg -I$(LIB) java

MSGS = MgmtQueryMsg.java MgmtQueryResponseMsg.java
INITIAL_TARGETS = $(MSGS)

ROOT = $(TOSDIR)/../tools/java
include $(ROOT)/Makefile.include

MgmtQueryMsg.java: $(LIB)/MgmtQuery.h
	$(MIG) -java-classname=$(PACKAGE).MgmtQueryMsg $(LIB)/MgmtQuery.h MgmtQueryMsg -o$@

MgmtQueryResponseMsg.java: $(LIB)/MgmtQuery.h
	$(MIG) -java-classname=$(PACKAGE).MgmtQueryResponseMsg $(LIB)/MgmtQuery.h MgmtQueryResponseMsg -o$@

cleanmig:
	rm -f $(MSGS)
