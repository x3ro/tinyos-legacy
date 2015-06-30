TOS = /home/xinl/broken/experimental/dim/tos
PACKAGE = net.tinyos.dim.GUI
MIG = mig java
JAVAC = javac

# List of message classes to build
MSGS = ConsoleCreateMsg.java ConsoleReplyMsg.java ConsoleDropMsg.java ConsoleStartMsg.java ConsoleQueryMsg.java
INITIAL_TARGETS = $(MSGS)
OTHER_CLEAN = cleanmig

all: $(MSGS)

ConsoleCreateMsg.java:
	$(MIG) -java-classname=$(PACKAGE).ConsoleCreateMsg -target=pc /home/xinl/GUI/ConsoleCmdMsg.h ConsoleCreateMsg >$@
	$(JAVAC) $@
ConsoleReplyMsg.java:
	$(MIG) -java-classname=$(PACKAGE).ConsoleReplyMsg -target=pc /home/xinl/GUI/ConsoleCmdMsg.h ConsoleReplyMsg >$@
	$(JAVAC) $@
ConsoleDropMsg.java:
	$(MIG) -java-classname=$(PACKAGE).ConsoleDropMsg -target=pc /home/xinl/GUI/ConsoleCmdMsg.h ConsoleDropMsg >$@
	$(JAVAC) $@
ConsoleStartMsg.java:
	$(MIG) -java-classname=$(PACKAGE).ConsoleStartMsg -target=pc /home/xinl/GUI/ConsoleCmdMsg.h ConsoleStartMsg >$@
	$(JAVAC) $@
ConsoleQueryMsg.java:
	$(MIG) -java-classname=$(PACKAGE).ConsoleQueryMsg -target=pc /home/xinl/GUI/ConsoleCmdMsg.h ConsoleQueryMsg >$@
	$(JAVAC) $@
cleanmig:
	rm -f $(MSGS)
