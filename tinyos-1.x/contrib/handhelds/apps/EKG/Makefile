# Basic EKG streaming interface

COMPONENT=EKGApp

USE_IP=True
SELECT_WIRED_OR_WIRELESS=True
USE_WEB=ekg.fun
USE_REGISTRAR=ekg

include ../Makerules

ifdef SAMPLE_SIZE
PFLAGS += -DEKG_SAMPLE_SIZE="$(SAMPLE_SIZE)"
else
PFLAGS += -DEKG_SAMPLE_SIZE="1"
endif

CLEAN_EXTRA += ekg.gladep