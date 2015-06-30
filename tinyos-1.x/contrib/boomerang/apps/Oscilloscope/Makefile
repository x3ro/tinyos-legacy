VALID_PLATFORMS = t telos telosa telosb tmote tmoteinvent
VALID_TARGETS = $(VALID_PLATFORMS) clean help
ifeq ($(filter $(VALID_TARGETS),$(MAKECMDGOALS)),)
$(error ERROR: Invalid platform!  Valid platforms: $(VALID_PLATFORMS))
endif

MOTEIV_DIR ?= ../../

COMP = $(if $(filter-out tmoteinvent,$(PLATFORM)),TmoteSky,TmoteInvent)

COMPONENT = Oscilloscope$(COMP)
CFLAGS += -DOSCOPE_MAX_CHANNELS=6
PFLAGS += -I$(TOSDIR)/lib/Oscope
PFLAGS += -DDELUGE_PAGETRANSFER_LEDS

# Override the ident program name since Deluge already reports the platform
# and otherwise the name is so long it is reported as just "OscilloscopeTmo".
IDENT_PROGRAM_NAME = Oscilloscope

include $(MAKERULES)

