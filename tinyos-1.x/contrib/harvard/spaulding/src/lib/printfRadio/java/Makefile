MIGFILES = SRC_$(SPAULDINGSRC)/lib/printfRadio/PrintfRadioMsgs.h__OUT_PrintfRadioMsg
NCGFILES = SRC_$(SPAULDINGSRC)/lib/printfRadio/PrintfRadioMsgs.h__OUT_PrintfRadio


nccSrc = $(patsubst SRC_%,%, $(filter SRC_%, $(subst __, ,$(1))))
nccOut = $(patsubst OUT_%,%, $(filter OUT_%, $(subst __, ,$(1))))
nccOutJava = $(addsuffix .java, $(call nccOut, $(1)))

include $(SPAULDINGSRC)/Makefile.in
#CFLAGS = -I.. -I../..

MIG = mig $(PFLAGS) $(CFLAGS) java
NCG = ncg $(PFLAGS) $(CFLAGS) java
JAVA = java -ea


all: mig ncg java

java:
	javac *.java

run:
	$(JAVA) PrintfRadioReceiver


mig: $(MIGFILES)
$(MIGFILES):
	@echo "  --> mig " $(call nccOut, $@);
	@$(MIG) -java-classname=$(call nccOut, $@) $(call nccSrc, $@) $(call nccOut, $@) > $(call nccOutJava, $@)

ncg: $(NCGFILES)
$(NCGFILES):
	@echo "  --> ncg " $(call nccOut, $@);
	@$(NCG) -java-classname=$(call nccOut, $@) $(call nccSrc, $@) $(call nccOut, $@).h > $(call nccOutJava, $@)


clean: 
	rm -f *.class

cleanall: clean
	rm -f $(call nccOutJava, $(MIGFILES))
	rm -f $(call nccOutJava, $(NCGFILES))



