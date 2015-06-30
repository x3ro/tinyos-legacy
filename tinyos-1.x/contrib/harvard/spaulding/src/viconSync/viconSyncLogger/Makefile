MIGFILES = SRC_../ViconSyncMsg.h__OUT_ViconSyncMsg \
	   SRC_../ViconSyncMsg.h__OUT_ViconSyncCmdMsg
#NCGFILES = SRC_../sampling/MercurySampling.h__OUT_MercurySampling

nccSrc = $(patsubst SRC_%,%, $(filter SRC_%, $(subst __, ,$(1))))
nccOut = $(patsubst OUT_%,%, $(filter OUT_%, $(subst __, ,$(1))))
nccOutJava = $(addsuffix .java, $(call nccOut, $(1)))

include $(SPAULDINGSRC)/Makefile.in
PFLAGS = -I.. -I../..
DFLAGS = -DTOSH_DATA_LENGTH=$(MSG_SIZE)

MIG = mig $(DFLAGS) $(PFLAGS) java
NCG = ncg java
JAVA = java -ea
JAVAC = javac #-Xlint:unchecked

# Cygwin or Linux: (';' for Cygwin, ':' for Linux)
ifneq ($(shell uname | grep -i CYGWIN),)
	override CLASSPATH := $(CLASSPATH);charting-0.94-konrad.jar
else
	override CLASSPATH := $(CLASSPATH):charting-0.94-konrad.jar
endif



all: mig ncg java

java:
	$(JAVAC) *.java

run:
	$(JAVA) ViconSyncLogger


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
	#rm -rf SpauldingGUI.jpx.local~ "package cache" "cache files"

cleanall: clean
	rm -f $(call nccOutJava, $(MIGFILES))
	rm -f $(call nccOutJava, $(NCGFILES))
	#rm -f SpauldingGUI.jpx.local
