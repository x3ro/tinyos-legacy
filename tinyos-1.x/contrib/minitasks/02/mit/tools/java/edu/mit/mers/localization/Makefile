sourceFiles := $(wildcard *.java)

objectFiles := $(sourceFiles:%.java=%.class)

all: $(objectFiles)

%.class : %.java
	javac $<

run: all
	java -classpath $(CLASSPATH):.:../../../.. edu.mit.mers.localization.LocationGUI 127.0.0.1 church

