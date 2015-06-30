SOURCES = DispatchIF.java Dispatcher.java LinkedMessage.java MoteIF.java Receiver.java
CLASSES = $(SOURCES:%.java=%.class)

all: $(CLASSES)

$(CLASSES): $(SOURCES)
	javac $(SOURCES)

clean: FORCE
	rm -f *.class

.PHONY: FORCE

