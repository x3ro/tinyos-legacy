all: Mig1Msg.java
	javac *.java

# maybe a ncc -print-tos-dir option would be nice...
Mig1Msg.java: ../../../../../../apps/TestMig1/Mig1Msg.h
	mig -java-classname=net.tinyos.tests.mig1.Mig1Msg java $< Mig1Msg >$@
