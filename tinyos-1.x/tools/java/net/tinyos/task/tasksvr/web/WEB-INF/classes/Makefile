SRC = $(wildcard *.java) 
JAVA = $(SRC)
CLASSES = $(JAVA:.java=.class)

all: $(JAVA) $(CLASSES)

# general rule for java files
%.class: %.java
	javac $<

