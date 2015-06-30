JAVA = FunctionVisitor.java FunctionCallVisitor.java VariableVisitor.java CodePrinter.java GSRVisitor.java MirroredVarVisitor.java
CLASSES = $(JAVA:.java=.class)

%.class: %.java
	javac $<

all: $(CLASSES)

clean:
	rm -f *.class DepthFirstVisitor.java ObjectDepthFirst.java ObjectVisitor.java TreeDumper.java TreeFormatter.java Visitor.java
