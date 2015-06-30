SUBDIRS = visitor syntaxtree

JAVA = Main.java NCSCompiler.java RequiredIF.java FunctionDef.java FunctionCall.java PeriodicDef.java CGVisitor.java Environment.java VariableDecl.java BlockSplitter.java DumpCallGraphVisitor.java Neighborhood.java MirroredVariableDecl.java
CLASSES = $(JAVA:.java=.class)

%.class: %.java
	javac $<

all: NCSParser.class $(CLASSES) subdirs

subdirs:
	@for i in $(SUBDIRS); do \
		if [ -d $$i ]; then \
			if [ -f $$i/Makefile ]; then \
				$(MAKE) -C $$i; \
			else \
				echo "***" no Makefile in directory: $(PWD)/$$i; \
			fi \
		else \
			echo "***" skipping missing directory: $(PWD)/$$i; \
		fi; \
	done

subdirs-clean:
	@for i in $(SUBDIRS); do \
		if [ -d $$i ]; then \
			if [ -f $$i/Makefile ]; then \
				$(MAKE) -C $$i clean; \
			else \
				echo "***" no Makefile in directory: $(PWD)/$$i; \
			fi \
		else \
			echo "***" skipping missing directory: $$i; \
		fi; \
	done

NCSParser.java: jtb.out.jj
	javacc $<

jtb.out.jj: ncs.jj
	jtb -p ncs.compiler -printer $<
	
clean: subdirs-clean
	rm -f *.class Token.java TokenManager.java TokenMgrError.java NCSParser.java NCSParserConstants.java NCSParserTokenManager.java ParseException.java SimpleCharStream.java jtb.out.jj
