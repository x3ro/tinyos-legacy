COMPONENT = TestDataStoreC

include $(SPAULDINGSRC)/DataStore/Makefile.in

# ----- For Debugging ---
# For Debugging, make sure that
#   1. PRINTFUART_ENABLED is enabled
#   2. DATASTORE_DEBUG_PRINT_ENABLED is enabled
#   3. the size of debugDSBlocks[][] in DataStoreM.nc is not too large!
#      Otherwise, it will take a *long* time to print the entire flash,
#      and you may run out of RAM. The size of the Flash can be adjusted
#      via the 3 parameters below
CFLAGS += -DPRINTFUART_ENABLED
CFLAGS += -DDATASTORE_DEBUG_PRINT_ENABLED

CFLAGS += -DBLOCK_DATA_SIZE=12
CFLAGS += -DDS_NBR_BLOCKS_PER_VOLUME=4
CFLAGS += -DDS_NBR_VOLUMES=3


#CFLAGS += -DDS_FORMAT_ENABLED

# Other
CFLAGS += -DLEDS_DATASTORE
#CFLAGS += -DDATASTORE_FAKE
CFLAGS += -DKNOWN_BLOCK_PATTERN


include $(MAKERULES)

