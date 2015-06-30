# $Id: Makefile,v 1.1.1.1 2007/01/10 21:10:50 lhuang2 Exp $

#									tab:2
#
#
# "Copyright (c) 2000-2005 The Regents of the University  of California.  
# All rights reserved.
#
# Permission to use, copy, modify, and distribute this software and its
# documentation for any purpose, without fee, and without written agreement is
# hereby granted, provided that the above copyright notice, the following
# two paragraphs and the author appear in all copies of this software.
# 
# IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
# DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
# OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY OF
# CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
# 
# THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
# INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
# AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
# ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
# PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
#
#

#
# @author Jonathan Hui <jwhui@cs.berkeley.edu>
#

COMPONENT=TOSBoot
TINYOS_NP=

DELUGE_TOSBOOT_DIR=%T/lib/Deluge/TOSBoot
PFLAGS += -I. -I.. -I$(DELUGE_TOSBOOT_DIR) -DNESC_BUILD_BINARY -Os

ifeq ($(MAKECMDGOALS),mica2)
  CFLAGS += -DTOSBOOT_START=0x1f000 -DTOSBOOT_END=0x20000
  CFLAGS += -Wl,--section-start=.text=0x1f000
  CFLAGS += -I$(DELUGE_TOSBOOT_DIR)/at45db -I$(DELUGE_TOSBOOT_DIR)/avr -I$(DELUGE_TOSBOOT_DIR)/mica2
endif

ifeq ($(MAKECMDGOALS),mica2dot)
  CFLAGS += -DTOSBOOT_START=0x1f000 -DTOSBOOT_END=0x20000
  CFLAGS += -Wl,--section-start=.text=0x1f000
  CFLAGS += -I$(DELUGE_TOSBOOT_DIR)/at45db -I$(DELUGE_TOSBOOT_DIR)/avr -I$(DELUGE_TOSBOOT_DIR)/mica2dot
endif

ifeq ($(MAKECMDGOALS),micaz)
  CFLAGS += -DTOSBOOT_START=0x1f000 -DTOSBOOT_END=0x20000
  CFLAGS += -Wl,--section-start=.text=0x1f000
  CFLAGS += -I$(DELUGE_TOSBOOT_DIR)/at45db -I$(DELUGE_TOSBOOT_DIR)/avr -I$(DELUGE_TOSBOOT_DIR)/micaz
endif

ifeq ($(MAKECMDGOALS),telosa)
  CFLAGS += -DTOSBOOT_START=0x1100 -DTOSBOOT_END=0x1a00
  CFLAGS += -I$(DELUGE_TOSBOOT_DIR)/at45db -I$(DELUGE_TOSBOOT_DIR)/msp430 -I$(DELUGE_TOSBOOT_DIR)/telos
  POST_BUILD_EXTRA_DEPS += strip_iv
endif

ifeq ($(MAKECMDGOALS),telosb)
  CFLAGS += -DTOSBOOT_START=0x4000 -DTOSBOOT_END=0x4800
  CFLAGS += -I$(DELUGE_TOSBOOT_DIR)/msp430 -I$(DELUGE_TOSBOOT_DIR)/stm25p -I$(DELUGE_TOSBOOT_DIR)/telosb -I$(DELUGE_TOSBOOT_DIR)/lib
  POST_BUILD_EXTRA_DEPS += strip_iv
endif

strip_iv: FORCE
	@echo "    removing interrupt vector from binary"
	msp430-objcopy -j .text -j .data -O ihex $(BUILDDIR)/main.exe $(BUILDDIR)/main.ihex

include $(MAKERULES)
