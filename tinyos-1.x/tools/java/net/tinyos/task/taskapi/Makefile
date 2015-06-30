SRC = $(wildcard *.java)
JAVA = $(SRC)
CLASSES = $(JAVA:.java=.class)

all: taskserver $(JAVA) $(CLASSES)

# general rule for java files
%.class: %.java
	javac $<

taskserver:
	$(MAKE) -C ../tasksvr

clean:
	rm -rf *.class
	$(MAKE) -C ../tasksvr clean
