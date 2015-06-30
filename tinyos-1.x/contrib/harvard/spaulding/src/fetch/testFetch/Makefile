COMPONENT = TestFetchC

include $(SPAULDINGSRC)/Makefile.in
include $(SPAULDINGSRC)/sampling/Makefile.in
include $(SPAULDINGSRC)/dataStore/Makefile.in
include $(SPAULDINGSRC)/samplingToDataStore/Makefile.in
include $(SPAULDINGSRC)/fetch/Makefile.in

TINYOS_NP=X  # Disable Deluge

PFLAGS += -DDS_FORMAT_ENABLED
PFLAGS += -DDS_NBR_VOLUMES=10
#PFLAGS += -DKNOWN_BLOCK_PATTERN
PFLAGS += -DPRINTFUART_ENABLED


include $(MAKERULES)

