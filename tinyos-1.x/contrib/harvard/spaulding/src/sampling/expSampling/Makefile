COMPONENT = TestMultiChanSamplingC

CFLAGS += -I$(SPAULDINGSRC)/lib/
CFLAGS += -I$(SPAULDINGSRC)/lib/printfRadio
include $(SPAULDINGSRC)/Makefile.in
include $(SPAULDINGSRC)/sampling/Makefile.in

# For RfmToLeds
# CFLAGS += -I$(TOSROOT)/apps/RfmToLeds
# CFLAGS += -I$(TOSROOT)/tos/lib/Counters

#CFLAGS += -DPRINTFUART_ENABLED
PFLAGS += -DPRINTFRADIO_ENABLED



MSP_BSL=/opt/tinyos-1.x/contrib/handhelds/tools/src/mspgcc-pybsl/bsl.py
include $(MAKERULES)

