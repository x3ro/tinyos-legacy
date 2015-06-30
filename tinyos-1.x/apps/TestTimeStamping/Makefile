COMPONENT=TestTimeStampingC
PFLAGS := -I%T/lib/DiagMsg -DDIAGMSG_RETRY_COUNT=1 

# type "CALIBRATE=true make mica2"
ifdef CALIBRATE
PFLAGS := $(PFLAGS) -DTIMESTAMPING_CALIBRATE
endif

include ../Makerules
