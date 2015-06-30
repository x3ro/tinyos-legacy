#these allow compiling using IBM's JavaComm for linux
#JAVACFLAGS=-extdirs /opt/IBMJava2-13/jre/lib/ext -classpath /opt/IBMJava2-13/jre/lib:.
UTILCLASSES = \
	net/tinyos/util/ForwarderListen.class \
	net/tinyos/util/PacketListenerIF.class \
	net/tinyos/util/SerialForwarderStub.class \
	net/tinyos/util/SerialPortStub.class \
	net/tinyos/util/SerialStub.class

SERIALFORWARDSOURCES = \
	net/tinyos/SerialForwarder/SerialForward.java \
	net/tinyos/SerialForwarder/ClientServicer.java \
	net/tinyos/SerialForwarder/ControlWindow.java \
	net/tinyos/SerialForwarder/ListenServer.java \
	net/tinyos/SerialForwarder/SerialPortIO.java

SERIALFORWARDCLASSES = $(SERIALFORWARDSOURCES:.java=.class)

SERIALFORWARDCLASSES += net/tinyos/SerialForwarder/ControlWindow$1.class

OSCILLOSCOPECLASSES = \
	net/tinyos/oscilloscope/oscilloscope.class \
	net/tinyos/oscilloscope/GraphPanel.class 

all: parseschema oscilloscope listen.class inject.class record.class 

parseschema : y.tab.c
	gcc -I../tos/include y.tab.c -lfl -o parseschema

y.tab.c : lex.yy.c parseschema.yacc
	bison -y parseschema.yacc -o y.tab.c

lex.yy.c : parseschema.lex
	flex -olex.yy.c parseschema.lex 

clean:
	rm -f y.tab.c lex.yy.c parseschema 
	rm -f $(SERIALFORWARDCLASSES)
	rm -f $(OSCILLOSCOPECLASSES)
	rm -f $(UTILCLASSES)
	rm -f serialforwarder.jar
	rm -f listen.class inject.class Hex.class record.class listen


oscilloscope: $(UTILCLASSES) $(SERIALFORWARDCLASSES) $(OSCILLOSCOPECLASSES) 

%.class: %.java
	javac $(JAVACFLAGS) $<
