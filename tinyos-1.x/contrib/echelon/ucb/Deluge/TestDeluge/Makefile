COMPONENT=TestDeluge
IDENT_PROGRAM_NAME=delugere

DEFAULT_LOCAL_GROUP := 0xc5

SCRIPTSDIR = $(TOSDIR)/../contrib/SystemC/scripts

PFLAGS += -I%T/../contrib/echelon/ucb/Deluge/Deluge 

#PFLAGS += -I%T/lib/MintRoute -I%T/lib/Queue
PFLAGS += -I%T/../contrib/echelon/ucb/Deluge/MintRoute -I%T/../contrib/echelon/ucb/Deluge/Queue

PFLAGS += $(shell $(SCRIPTSDIR)/ident.pl ../.ident_install_id $(IDENT_PROGRAM_NAME))

#PFLAGS += -I%T/../beta/TOSSIM-PageEEPROM 

#PFLAGS += -DDELUGE_REPORTING_UART
PFLAGS += -DDELUGE_REPORTING_MHOP
PFLAGS += -DMULTI_HOP_DEBUG

include $(TOSDIR)/../apps/Makerules
