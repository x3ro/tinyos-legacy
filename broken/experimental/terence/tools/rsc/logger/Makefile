
#/* -*- Mode: Makefile; c-basic-indent: 2; indent-tabs-mode: nil -*- */ 
#/* $Id: Makefile,v 1.6 2003/04/01 08:26:13 wetoasis Exp $ */
#/*////////////////////////////////////////////////////////*/
#/**
# * 
# * Author: Terence Tong
# */
#/*////////////////////////////////////////////////////////*/

# please edit this relative path accordingly to message in the java tools directory
MESSAGE_DIR = ../../../../../../tinyos-1.x/tools/java/net/tinyos/message
JAVAC = javac -target 1.1
TMP = packet
all: migmessage messages rsc

migmessage: 
	$(JAVAC) $(MESSAGE_DIR)/*.java

rsc:
	$(JAVAC) *.java

TARGET = StatPacket TablePacket RouteDBMsg RoutePacket SurgeMsg EstimatorMsg
# don't know why mig HAVE TO HAVE a package, so I kill it
messages: 
	for message in $(TARGET); do \
		echo ">> Generating $$message.java ....."; \
		mig java -java-classname=$(TMP).$$message Packets.h $$message > $$message.java; \
		echo ">> Killing the package in $$message.java"; \
		sed -e 's/package $(TMP);//g' $$message.java > $$message.temp; \
		mv $$message.temp $$message.java; \
	done
regen: clean messages rsc

clean:
	rm *.class

