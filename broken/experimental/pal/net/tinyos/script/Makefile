# Note that Yylex has to be made before QueryParser

TREE = $(wildcard tree/*.java)
JAVART=/root/src/tinyos-1.x/tools/java
ASM=net/tinyos/vm_asm
SCRIPT=net/tinyos/script
UTIL=net/tinyos/util
MSG=net/tinyos/message
SIM=net/tinyos/sim
PACKET=net/tinyos/packet

all: Parser.class sym.class Yylex.class Main.class scripter tree builder
	javac tree/*.java

builder: VMBuilder.class BuilderMenu.class InstructionPanel.class VMDescriptionDialog.class ContextPanel.class VMFileGenerator.class VMBuilderFromFile.class VMOptions.class

scripter: Scripter.class ScriptInjector.class ScriptAssembler.class AssemblyTokenizer.class

Parser.java: Parser.cup
	java java_cup.Main -parser Parser < Parser.cup

Parser.class: Parser.java Yylex.class
	javac Parser.java

Parser.lex.java: Parser.lex
	java JLex.Main Parser.lex

Yylex.java: Parser.lex.java
	cp Parser.lex.java Yylex.java

%.class: %.java
	javac $<

run:
	java net.tinyos.script.Main < prog.tb

tree:   $(TREE)
	javac tree/*.java

clean: 
	rm -f *.class Yylex.java Parser.java sym.java *~ Parser.lex.java


jarfiles: Scripter.jar VMBuilder.jar

Scripter.jar:
	(cd $(JAVART); pwd;jar cmf $(SCRIPT)/scripter.manifest $(SCRIPT)/scripter.jar $(SCRIPT)/*.class $(SCRIPT)/tree/*.class $(ASM)/BombillaErrorMsg.class $(ASM)/ConstantMapper.class $(ASM)/InvalidInstructionException.class $(MSG)/*.class $(PACKET)/*.class $(UTIL)/*.class $(SIM)/packet/*.class $(SIM)/msg/*.class $(SIM)/*.class $(SIM)/event/*.class)

VMBuilder.jar:
	(cd $(JAVART); pwd;jar cmf $(SCRIPT)/vmbuilder.manifest $(SCRIPT)/vmbuilder.jar $(SCRIPT)/*.class $(SCRIPT)/tree/*.class $(UTIL)/TinyLook.class)


