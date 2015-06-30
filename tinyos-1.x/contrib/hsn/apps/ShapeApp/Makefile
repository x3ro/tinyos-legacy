COMPONENT=TinyDBApp
SENSORBOARD=micasb
# Real Motes Mica 0~100, 1 max. Mica2 0~255 1 min
ifdef SINK_NODE
  TXRES_VAL=7
else
  TXRES_VAL=8
endif
# Real Motes Mica 42, Mica2 49, Simulator 50. TinyDBMain.java:DATA_SIZE!!
MSG_SIZE=49
MICA2_900MHZ=1

PFLAGS=-I./tos_patch -I$(BASEDIR)lib/Util -I$(BASEDIR)lib/Attributes -I$(BASEDIR)lib/Commands -I$(BASEDIR)lib/TinyDB -I$(BASEDIR)lib/FS -I$(BASEDIR)lib/TinyDB/Aggregates

PFLAGS += -DNETWORK_MODULE=TinyDBShim -DGENERICCOMM=PromiscuousCommNoUART -DGENERICCOMMPROMISCUOUS=PromiscuousCommNoUART -DBOARD_MICASB -fno-strict-aliasing

PFLAGS += -DRUPDATE_RANDOMIZE -DDSDV_RUPINT_DEFAULT=30
#PFLAGS += -DRUPDATE_RANDOMIZE -DDSDV_RUPINT_DEFAULT=10

# ADJUVANT_NODE_ID = ID only use in simulator to specify Adj node id
# Don't define SINK_NODE or = 0 when Simulator
PFLAGS += -DHSN_ROUTING #-DADJUVANT_NODE_ID=1

# To help against asymetric links
PFLAGS += -DDSDV_BI_DIR_QUALITY=1

# When using HSN_ROUTING, adjuvant node hi-jact packet which breaks passive ack
DSDV_PASSIVE_ACK=0

# EnergyMetric - Use energy metric instead of reliability under SoI
# SOI_ENERGY_WALLPOWER - under EnergyMetric, when setting a node to be
# SoI special node, it becomes wall power node automatically
PFLAGS += #-DENERGY_METRIC #-DSOI_ENERGY_WALLPOWER

# Let HSN to flood query, in additional to TinyDB's query flooding. More stable
PFLAGS += #-DTINYDBSHIM_FLOOD_QUERY

# Let Sink node to fwd Settings from UART, only work with HSN_ROUTING enabled
PFLAGS += -DTINYDBSHIM_FWD_SETTINGS

# TinyDBShim jitter to delay SendDataMessage & random delay from 0 ~ 3.2 sec
PFLAGS += #-DTINYDBSHIM_JITTER=1 -DTINYDBSHIM_JITTER_FACTOR=32

# DSDV Related Settings, AGE_CACHE_TIMEOUT < 3 is required for energy metrix
PFLAGS += -DNEIGHBOR_AGE_CACHE_TIMEOUT=3 -DDUPLICATE_REMOVAL=1 #-DDSDV_PARENT_TIMEOUT=3

# To provide TraceRoute
# TR_PIGGYBACK_LEN = 2 is for energy measure thou parse_and_print only decode 1
# and it makes the parse_and_print can't decode the adj. bit before piggyback
# TR_PLUGIN_LEN = 3 is for HSNValue
PFLAGS += -DTRACE_ROUTE -DTR_SEND_RATE=9999 -DTR_PIGGYBACK_LEN=1 -DTR_PLUGIN_LEN=2

# To provide energy measure settings and piggyback current value in TR
PFLAGS += #-DTINYDBSHIM_ENERGY_MEASURE=1

# Not to smooth the energy to get better result for TinyDB aggregation query
PFLAGS += -DSMOOTH_ENERGY=0

# Real - Talk to TinyDB and WSN apps
#   Default HSN frame - uart. COM2 9001 -r49 9000 and old-sf@57600,49
#   NO_UART_FRAMED - uart. 9001 -r49 COM2 9000 + old-sf@57600 or old-serial@5760
#   TINYOS_UART_FRAMED - serial@57600
# Simulator - set tinydb.conf SF to TRUE and use NO_FRAMED
PFLAGS += #-DTINYOS_UART_FRAMED #-DNO_UART_FRAMED #-DTINYDBSHIM_UART_MEASURE

# To reduce RAM size, can't more than 3K
#PFLAGS += -DCONST_NEIGHBOR_LIST_LEN=15 -DCONST_GSET_MAX_FEEDBACK_VALUES=1

include ../MakeHSN
