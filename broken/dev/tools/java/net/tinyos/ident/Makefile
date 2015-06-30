TOS=$(shell ncc -print-tosdir)
APPS=$(TOS)/../apps

PACKAGE = net.tinyos.ident
APP=$(APPS)/Ident

MIG = mig -I$(APP) java

MSGS = IdentMsg.java SetIdMsg.java ClearIdMsg.java

all: $(MSGS)
	javac *.java

IdentMsg.java:
	$(MIG) -java-classname=$(PACKAGE).IdentMsg $(APP)/App.td IdentMsg -o$@

SetIdMsg.java:
	$(MIG) -java-classname=$(PACKAGE).SetIdMsg $(APP)/App.td SetIdMsg -o$@

ClearIdMsg.java:
	$(MIG) -java-classname=$(PACKAGE).ClearIdMsg $(APP)/App.td ClearIdMsg -o$@

clean:
	rm $(MSGS) *.class
