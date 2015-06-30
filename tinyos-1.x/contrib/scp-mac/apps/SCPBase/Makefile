COMPONENT=SCPBase

PLATFORM = mica2

TOSNIC_ROOT = ../../../nic
SCPMAC_ROOT = ../..

PROJECT_TOSDIR = ${TOSNIC_ROOT}/tos
COMMDIR = ${SCPMAC_ROOT}/tos

INCLUDE := -I. -I../SCPBase/ 

INCLUDE += -I ${TOSNIC_ROOT}/ -I${TOSNIC_ROOT}/include/ -I${TOSNIC_ROOT}/tos/ -I${TOSNIC_ROOT}/tos/interfaces/ -I${TOSNIC_ROOT}/tos/lib/ -I${TOSNIC_ROOT}/tos/platform/${PLATFORM}/ -I${TOSNIC_ROOT}/tos/system/

INCLUDE += -I${SCPMAC_ROOT}/tos/interfaces -I${SCPMAC_ROOT}/tos/system -I${SCPMAC_ROOT}/tos/platform/$(PLATFORM)


include ../Makeapps
