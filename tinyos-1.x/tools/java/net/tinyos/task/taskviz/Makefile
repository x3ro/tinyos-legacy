SRC = $(wildcard *.java)
JAVA = $(SRC)
CLASSES = $(JAVA:.java=.class)

all: taskapi $(JAVA) $(CLASSES)

# general rule for java files
%.class: %.java
	javac $<

taskapi:
	$(MAKE) -C ../taskapi

clean:
	rm -rf *.class sensor/*.class
	$(MAKE) -C ../taskapi clean
