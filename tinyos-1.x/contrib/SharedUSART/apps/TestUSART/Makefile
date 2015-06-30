VALID_PLATFORMS = telos telosa telosb tmote
VALID_TARGETS = $(VALID_PLATFORMS) clean help
ifeq ($(filter $(VALID_TARGETS),$(MAKECMDGOALS)),)
$(error ERROR: Invalid platform!  Valid platforms: $(VALID_PLATFORMS))
endif

COMPONENT = TestUSART

include $(MAKERULES)
