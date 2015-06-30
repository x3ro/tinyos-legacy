MIGFILES = SRC_$(SPAULDINGSRC)/sampling/SamplingMsg.h__OUT_SamplingMsg \
           SRC_$(SPAULDINGSRC)/lib/ErrorToLeds.h__OUT_ErrorToLedsMsg
NCGFILES = SRC_$(SPAULDINGSRC)/sampling/MercurySampling.h__OUT_MercurySampling \
	   SRC_$(SPAULDINGSRC)/sampling/MultiChanSampling.h__OUT_MultiChanSampling

nccSrc = $(patsubst SRC_%,%, $(filter SRC_%, $(subst __, ,$(1))))
nccOut = $(patsubst OUT_%,%, $(filter OUT_%, $(subst __, ,$(1))))
nccOutJava = $(addsuffix .java, $(call nccOut, $(1)))

include $(SPAULDINGSRC)/Makefile.in
#PFLAGS = -I.. -I../..


MIG = mig $(DFLAGS) $(PFLAGS) java
NCG = ncg $(DFLAGS) $(PFLAGS) java
JAVA = java -ea

# Cygwin or Linux: (';' for Cygwin, ':' for Linux)
ifneq ($(shell uname | grep -i CYGWIN),)
	override CLASSPATH := $(CLASSPATH);charting-0.94-mdw.jar
else
	override CLASSPATH := $(CLASSPATH):charting-0.94-mdw.jar
endif



all: mig ncg java

java:
	javac *.java

run:
	$(JAVA) ReceiverGUI


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
	rm -rf ReceiverGUI.jpx.local~ "package cache"

cleanall: clean
	rm -f $(call nccOutJava, $(MIGFILES))
	rm -f $(call nccOutJava, $(NCGFILES))
	rm -f ReceiverGUI.jpx.local



