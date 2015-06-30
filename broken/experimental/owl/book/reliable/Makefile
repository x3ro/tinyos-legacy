COMPONENT=TestSerialAppC
BUILD_EXTRA_DEPS += TestSerial.class
CLEAN_EXTRA = *.class TestSerialMsg.java AckMsg.java ReliableMsg.java RelConstants.java

TestSerial.class: $(wildcard *.java) TestSerialMsg.java AckMsg.java ReliableMsg.java RelConstants.java
	javac *.java

TestSerialMsg.java:
	mig java -target=null $(CFLAGS) -java-classname=TestSerialMsg TestSerial.h test_serial_msg -o $@

AckMsg.java:
	mig java -target=null $(CFLAGS) -java-classname=AckMsg reliableserial.h ack_msg -o $@


ReliableMsg.java:
	mig java -target=null $(CFLAGS) -java-classname=ReliableMsg reliableserial.h reliable_msg -o $@

RelConstants.java:
	ncg java -target=null $(CFLAGS) -java-classname=RelConstants reliableserial.h ACK_TIMEOUT -o $@


include $(MAKERULES)

