MSGNAME = TestPerformanceMsg
MSGSRC = ../TestPerformanceMsg.h

PFLAGS += -I..

all: mig
	javac *.java

run:
	java JavaReceiver

mig:
	@for i in $(MSGNAME); do \
		echo "  --> mig $$i"; mig java -java-classname=$$i ${MSGSRC} $$i > $$i.java; \
	done	

clean:
	@for i in $(MSGNAME); do \
		echo "  --> rm $$i.java"; rm -f $$i.java; \
	done

	rm -f *.class
