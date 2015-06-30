COMPONENT = TestPerformanceC

include $(SPAULDINGSRC)/Makefile.in
include $(SPAULDINGSRC)/dataStore/Makefile.in

CFLAGS += -I$(SPAULDINGSRC)/lib/
CFLAGS += -I$(SPAULDINGSRC)/lib/printfRadio

# ----- For Debugging ---
# For Debugging, make sure that
#   1. DATASTORE_DEBUG_PRINT_ENABLED is enabled
#   2. PRINTFUART_ENABLED is enabled
#   3. the size of debugDSBlocks[][] in DataStoreM.nc is not too large!
#      Otherwise, it will take a *long* time to print the entire flash,
#      and you may run out of RAM. The size of the Flash can be adjusted 
#      via the 3 parameters below
#CFLAGS += -DDATASTORE_DEBUG_PRINT_ENABLED  
#CFLAGS += -DPRINTFUART_ENABLED

#CFLAGS += -DBLOCK_DATA_SIZE=240
#CFLAGS += -DDS_NBR_BLOCKS_PER_VOLUME=3
#CFLAGS += -DDS_NBR_VOLUMES=3


include $(MAKERULES)

