MIG=mig java -target=mica2

include ../../../../../BaseDIR
HSNDIR = ../../../../../../tos

GSKINCLUDES = -DHSN_ROUTING -DNETWORK_MODULE=TinyDBShim -DTOSH_DATA_LENGTH=49 -DGENERICCOMM=PromiscuousCommNoUART -DGENERICCOMMPROMISCUOUS=PromiscuousCommNoUART -DBOARD_MICASB

GSKINCLUDES += -I$(HSNDIR)/../apps/TinyDBApp/tos_patch -I$(HSNDIR)/lib -I$(HSNDIR)/lib/neighborhood -I$(HSNDIR)/interfaces -I$(HSNDIR)/system -I$(HSNDIR)/../apps/TinyDBApp

GSKINCLUDES += -DBUILD_DAY=$(shell date +%d | sed 's/^0//')
GSKINCLUDES += -DBUILD_MONTH=$(shell date +%m | sed 's/^0//')
GSKINCLUDES += -DBUILD_YEAR=$(shell date +%y | sed 's/^0//')

INCLUDES = $(GSKINCLUDES)
include MakeInclude
