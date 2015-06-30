COMPONENT=Agilla
include ./Makefile.Agilla       

PFLAGS+=$(PFLAGS_AGILLA)\
       -I components/ContextDiscovery \
       -I components/AgentReceiver \
       -I components/AgentSender \
       -I components/NetworkInterface \
       -I components/LocationReporter \
       -I components/ClusterheadDirectory \
       -I components \
       -I opcodes \
       -I contexts \
       -I types \
       -I interfaces \
       -I ../SpaceLocalizer \
       -I ../LEDBlinker

#MSG_SIZE=27

include $(TOSROOT)/tools/make/Makerules

#Use the following Makerules for dsys25 motes
#include $(TOSROOT)/apps/Makerules
