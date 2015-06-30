MIGFILES = SRC_../driver/DriverMsgs.h__OUT_RequestMsg \
           SRC_../driver/DriverMsgs.h__OUT_ReplyMsg \
           SRC_../sampling/SamplingMsg.h__OUT_SamplingMsg \
           SRC_../fetch/FetchMsgs.h__OUT_FetchRequestMsg \
	       SRC_../fetch/FetchMsgs.h__OUT_FetchReplyMsg \
           SRC_../lib/ErrorToLeds.h__OUT_ErrorToLedsMsg
NCGFILES = SRC_../sampling/MultiChanSampling.h__OUT_MultiChanSampling \
	   SRC_../fetch/FetchMsgs.h__OUT_FetchMsgs \
	   SRC_../driver/DriverMsgs.h__OUT_DriverMsgs


nccSrc = $(patsubst SRC_%,%, $(filter SRC_%, $(subst __, ,$(1))))
nccOut = $(patsubst OUT_%,%, $(filter OUT_%, $(subst __, ,$(1))))
nccOutJava = $(addsuffix .java, $(call nccOut, $(1)))

include $(SPAULDINGSRC)/Makefile.in
MIG = mig $(DFLAGS) $(PFLAGS) java
NCG = ncg -target=telos -I$(TOSDIR)/lib/CC2420Radio $(DFLAGS) $(PFLAGS) java
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
	$(JAVAC)  *.java

run:
	$(JAVA) SpauldingApp


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
	rm -rf SpauldingGUI.jpx.local~ "package cache" "cache files"

cleanall: clean
	rm -f $(call nccOutJava, $(MIGFILES))
	rm -f $(call nccOutJava, $(NCGFILES))
	rm -f SpauldingGUI.jpx.local
