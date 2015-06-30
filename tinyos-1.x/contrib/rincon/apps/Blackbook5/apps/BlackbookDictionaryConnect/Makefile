COMPONENT=BlackbookDictionaryConnectC

# Choose a flash type:
#CFLAGS += -I../../media/AT45DB
CFLAGS += -I../../media/STM25P

# Default include directories:
CFLAGS +=  -I../../ -I../../core -I../../interfaces -I../../boot
CFLAGS += -I../FlashBridgeViewer
CFLAGS += -I../../../../tos/lib/State 

# Compiler optimizer flag:
CFLAGS += -Os

# If you use Boomerang, comment this line out:
CFLAGS += -I../../../../tos/lib/Transceiver

# If you use Boomerang, uncomment these lines:
# CFLAGS += -DSTM25P_BOOMERANG_VERSION
# CFLAGS += -I../../../../tos/lib/sptransceiver

include $(MAKERULES)


