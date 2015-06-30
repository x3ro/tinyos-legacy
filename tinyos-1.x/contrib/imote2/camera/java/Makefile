PACKAGE = #codeBlue.gui.
MSGNAME = HWTestMsg
MSGSRC = ../HWTest.h
MIG_DIRS = -I..

CP_FLAG = #-classpath "$(CLASSPATH);../..;resources\charting-0.94-mdw.jar"

all: $(MSGNAME).java  consts
	javac $(CP_FLAG) *.java

runCons:
	java $(CP_FLAG) $(PACKAGE)CodeBlueConsoleGUI

consts:
	ncg  -java-classname=cmd  java  ../HWTest.h HWTest.h -ocmd.java


mig $(MSGNAME).java:
	@for i in $(MSGNAME); do \
		echo "  --> mig $$i"; mig $(MIG_DIRS) java -java-classname=$(PACKAGE).$$i $(MSGSRC) $$i > $$i.java; \
	done

clean:
	rm -f *.class platform.properties


cleanmig:
	@for i in $(MSGNAME); do \
		echo "  --> cleanmig $${i}.java"; rm -f $$i.java; \
	done

cleanall: clean cleanmig
	rm -rf "package cache"
	rm -rf Backup
	rm -rf *~* cmd.java


