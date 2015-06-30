# Note that Yylex has to be made before QueryParser

TREE = $(wildcard tree/*.java)
ASM=net/tinyos/vm_asm
SCRIPT=net/tinyos/script
UTIL=net/tinyos/util
MSG=net/tinyos/message
SIM=net/tinyos/sim
PACKET=net/tinyos/packet
FILES = Parser.class sym.class Yylex.class scripter tree builder OptionPanel.class Configuration.class AdvancedPanel.class AssemblyTokenizer.class BombillaErrorMsg.class BuilderInstruction.class BuilderMenu.class Capsule.class CapsuleSelector.class CodeWriter.class ConfigurationException.class Configuration.class ConfigurationTokenizer.class ConfStatement.class ConstantMapper.class ContextCellRenderer.class ContextPanel.class DFStatement.class DFTokenizer.class ErrorDialog.class Function.class FunctionTable.class InstructionPanel.class InvalidInstructionException.class NoFreeVariableException.class OpcodeAssigner.class OpcodeTable.class OpcodesExhaustedException.class OpcodesUnassignedException.class OptionPanel.class OptionSelector.class ParseException.class Primitive.class PrimitiveCellRenderer.class PrimitiveInfoPanel.class PrimitivePanel.class PrimitiveSelectionListener.class ProgramTokenizer.class ScriptAssembler.class Scripter.class TreeNode.class VariablePanel.class VMBuilderFromFile.class VMBuilder.class VMDescriptionDialog.class VMFileGenerator.class VMOptions.class  Function.class FunctionPanel.class FunctionCellRenderer.class FunctionInfoPanel.class TinyScriptCompiler.class ProgramAreaPanel.class ScripterMenuBar.class FunctionListPanel.class FunctionSet.class VMDescription.class CompiledTable.class VersionTable.class ProgramTable.class ScripterWindowed.class ScripterCommandLine.class ProgramState.class VMBufferReader.class Operation.class Context.class ScriptInjector.class


all: $(FILES)
	javac tree/*.java
	javac oscope/*.java

builder: BuilderMenu.class InstructionPanel.class VMDescriptionDialog.class ContextPanel.class VMFileGenerator.class VMBuilderFromFile.class VMOptions.class VMBuilderGui.class VMBuilder.class 

scripter: Scripter.class ScriptAssembler.class AssemblyTokenizer.class

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
	rm -f *.class Yylex.java Parser.java sym.java *~ Parser.lex.java tree/*.class oscope/*.class

