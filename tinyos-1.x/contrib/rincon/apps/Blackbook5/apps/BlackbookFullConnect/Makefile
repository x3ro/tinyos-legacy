COMPONENT=BlackbookFullConnectC

# Choose a flash type:
#CFLAGS += -I../../media/AT45DB
CFLAGS += -I../../media/STM25P

# Standard include directories:
CFLAGS +=  -I../../ -I../../core -I../../interfaces -I../../boot
CFLAGS += -I../FlashBridgeViewer
CFLAGS += -I../../../../tos/lib/State 

# If you use Boomerang, comment out this line:
CFLAGS += -I../../../../tos/lib/Transceiver

# If you use Boomerang, uncomment the following lines
# and comment out the above Transceiver line
#CFLAGS += -DSTM25P_BOOMERANG_VERSION
#CFLAGS += -I../../../../tos/lib/sptransceiver

# Compiler optimizer flag:
CFLAGS += -Os

include $(MAKERULES)

