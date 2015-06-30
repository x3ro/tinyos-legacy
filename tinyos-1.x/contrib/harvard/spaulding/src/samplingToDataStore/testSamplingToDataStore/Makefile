COMPONENT = TestSamplingToDataStoreC

include $(SPAULDINGSRC)/Makefile.in
include $(SPAULDINGSRC)/sampling/Makefile.in
include $(SPAULDINGSRC)/dataStore/Makefile.in
include $(SPAULDINGSRC)/samplingToDataStore/Makefile.in

PFLAGS += -I$(SPAULDINGSRC)/sampling/testSampling


# ----- For Debugging ---
# For Debugging, make sure that
#   1. PRINTFUART_ENABLED is enabled
#   2. DATASTORE_DEBUG_PRINT_ENABLED is enabled
#      The size of the Flash can be adjusted via the 3 parameters below
#CFLAGS += -DDATASTORE_DEBUG_PRINT_ENABLED
#CFLAGS += -DBLOCK_DATA_SIZE=26
#CFLAGS += -DDS_NBR_BLOCKS_PER_VOLUME=4
#CFLAGS += -DDS_NBR_VOLUMES=3

#PFLAGS += -DDS_FORMAT_ENABLED
#PFLAGS += -DDS_ERASE_VOLUMES_ENABLED  # only valid '#ifndef DS_FORMAT_ENABLED'
#CFLAGS += -DBLOCK_PRINT_SAMPLECHUNK
#PFLAGS += -DDATASTORE_DEBUG_PRINT_ENABLED
#PFLAGS += -DKNOWN_BLOCK_PATTERN
#PFLAGS += -DPRINTFUART_ENABLED


include $(MAKERULES)

