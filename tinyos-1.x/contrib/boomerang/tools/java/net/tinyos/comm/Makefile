SOURCES = ByteQueue.java NativeSerial.java SerialPort.java SerialPortEvent.java TOSCommJNI.java TOSCommLibraryLoader.java TOSSerial.java UnsupportedCommOperationException.java
CLASSES = $(SOURCES:%.java=%.class)

all: $(CLASSES)

$(CLASSES): $(SOURCES)
	javac $(SOURCES)

clean: FORCE
	rm -f *.class

.PHONY: FORCE

