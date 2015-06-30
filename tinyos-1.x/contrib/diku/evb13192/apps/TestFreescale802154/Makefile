# Makefile for TestSMAC application. 

# Note the use of ENVIRONMENT=FFD to get the make system to include
# the full function 802.15.4. library. 
COMPONENT=TestMain
ENVIRONMENT=FFD
#ENVIRONMENT=RFDNBNS
# Include the TinyOS 802.15.4 interface files by Joe Polastre
#IFPath=$(TOSROOT)/beta/lib/802.15.4
#PFLAGS=-I$(IFPath)/MLME/ \
#       -I$(IFPath)/MCPS/ \
#       -I$(IFPath)/

PFLAGS=-I$(TINYOS_EVB13192DIR)/tos/lib/freescale802154

# Now, this should go last!
include ../Makerules
