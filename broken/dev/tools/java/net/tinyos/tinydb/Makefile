TOS = $(shell ncc -print-tosdir)
PACKAGE = net.tinyos.tinydb
MIG = mig java
INCLUDES = -I $(TOS)/lib/Commands -I $(TOS)/lib/Attributes -I $(TOS)/lib/TinyDB -I $(TOS)/sensorboards/micasb
SRC = $(wildcard *.java)
JAVA = $(SRC)
CLASSES = $(JAVA:.java=.class)


all: message util sf QueryResultMsg.java QueryMsg.java UartMsg.java CommandMsg.java aparser $(JAVA) $(CLASSES) topology/*.java

# general rule for java files
%.class: %.java
	javac $<

QueryResultMsg.java:
	$(MIG) $(INCLUDES) -java-classname=$(PACKAGE).QueryResultMsg $(TOS)/../apps/TinyDBApp/TinyDBApp.td QueryResultMsg >$@

QueryMsg.java:
	$(MIG) $(INCLUDES) -java-classname=$(PACKAGE).QueryMsg $(TOS)/../apps/TinyDBApp/TinyDBApp.td QueryMessage >$@


UartMsg.java:
	$(MIG) $(INCLUDES) -java-classname=$(PACKAGE).UartMsg $(TOS)/../apps/TinyDBApp/TinyDBApp.td UartMsg >$@

CommandMsg.java:
	$(MIG) $(INCLUDES) -java-classname=$(PACKAGE).CommandMsg $(TOS)/../apps/TinyDBApp/TinyDBApp.td CommandMsg >$@


topology: topology/*.java
	javac topology/*.java

message:
	cd ../message
	make -C ../message -f Makefile

util: 
	cd ../util
	make -C ../util -f Makefile

sf: 
	cd ../sf
	make -C ../sf -f Makefile

text:
	java net.tinyos.tinydb.TinyDBMain -text

gui:
	java net.tinyos.tinydb.TinyDBMain -gui

run:
	java net.tinyos.tinydb.TinyDBMain

aparser:
	cd parser	
	make -C parser -f Makefile
#	javac parser/senseParser.java

clean:
	rm -f QueryMsg.java QueryResultMsg.java UartMsg.java CommandMsg.java
	rm -rf *.class
	rm -rf topology/*.class
	make -C parser clean
	make -C ../sf clean
	make -C ../message clean
	make -C ../util clean

