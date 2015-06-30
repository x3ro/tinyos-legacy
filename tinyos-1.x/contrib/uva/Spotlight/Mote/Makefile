COMPONENT=spotlight
SENSORBOARD=micasb
PLATFORMS = mica2 pc xsm xsm2 mica2dot 
SPOTLIGHT_PLATFORM:=$(filter $(PLATFORMS), $(MAKECMDGOALS))

PFLAGS = -I%T/lib/Util 

BUILDDIR = build/$(PLATFORM)
MAIN_EXE = $(BUILDDIR)/main.exe
MAIN_SREC = $(BUILDDIR)/main.srec
MAIN_IHEX = $(BUILDDIR)/main.ihex

ifeq ($(SPOTLIGHT_PLATFORM)_x,xsm2_x)
PFLAGS := $(PFLAGS) -I../PLATFORM/XSM2 -I../PLATFORM/COMMON -DPLATFORM_XSM2
endif

PFLAGS := $(PFLAGS) -I../TIME/TIMER -I../TIME/SYNC -DREACTIVE

include ../Makerules


ifeq ($(SPOTLIGHT_PLATFORM)_x,xsm_x)
BOOTLOADER=../DOWNLOAD/Deluge/TOSBoot/bl_xsm.srec
endif

ifeq ($(SPOTLIGHT_PLATFORM)_x,xsm2_x)
BOOTLOADER=../DOWNLOAD/Deluge/TOSBoot/bl_xsm.srec
endif

ifeq ($(SPOTLIGHT_PLATFORM)_x,mica2_x)
BOOTLOADER=../DOWNLOAD/Deluge/TOSBoot/bl_mica2.srec
endif


# define flags for loading bootloader for in-network programming using
# MIB510 serial programming.
PROGRAMMER_FLAGS_INP=-dprog=mib510 -dserial=$(MIB510) -dpart=ATmega128
