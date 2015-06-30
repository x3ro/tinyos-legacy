# $Id: Makefile,v 1.4 2004/07/08 00:06:25 mturon Exp $

COMPONENT=TASKApp

# Specify deployment specific configuration file.
include MakeConfig.MDA300
#include MakeConfig.MTS310
#include MakeConfig.Sensi310

# Shared TinyDB libraries
PFLAGS += -I../../tos/lib/TinyDB -I%T/lib/Util -I%T/lib/Attributes -I%T/lib/Commands -I%T/lib/TinyDB -I%T/lib/TinyDB/Aggregates -fno-strict-aliasing 

# Shared Networking libraries
PFLAGS += -I%T/lib/Queue  -I%T/lib/FS 

# use AWoo's MintRoute as routing layer
#PFLAGS += -I%T/lib/MintRoute 

# use the JHill's Reliable_Low_Power as routing layer
PFLAGS += -I%T/../contrib/ucb/tos/CC1000Pulse -I%T/../contrib/xbow/tos/lib/ReliableRoute_Low_Power -fnesc-include=CompileDefines -DUSE_LOW_POWER_LISTENING -DMULTIHOPROUTER=EWMAMultiHopRouter

MSG_SIZE=49

include ${TOSROOT}/apps/Makerules
