
COMPONENT=fabApp
SMACDIR=../../../contrib/s-mac/tos/
                                                                                
ifdef SMACDIR
include $(SMACDIR)/../apps/Makesmac
else
# assume SMACDIR is ../../tos
include ../Makesmac
endif
CFLAGS += -DCC1K_DEFAULT_FREQ=0x1 
#-DMEASURE_STATS

