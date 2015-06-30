# $Id: Makefile,v 1.1.1.1 2007/11/05 19:11:24 jpolastre Exp $

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

TINYOS_NP=
MOTEIV_DIR ?= ../../../../
TOSDIR ?= $(shell ncc -print-tosdir)
DELUGE_DIR = $(TOSDIR)/lib/Deluge
TOSBOOT_DIR = $(DELUGE_DIR)/TOSBoot
COMPONENT = TOSBoot
INLINE_LIMIT ?= 1000

CFLAGS += -I.
CFLAGS += -I..

ifneq ($(filter t tmote tmoteinvent,$(MAKECMDGOALS)),)
  CFLAGS += -DTOSBOOT_START=0x4000
  CFLAGS += -DTOSBOOT_END=0x4800
  CFLAGS += -Imsp430
  CFLAGS += -Istm25p
  ifeq ($(filter tmoteinvent,$(MAKECMDGOALS)),tmoteinvent)
    CFLAGS += -Itmoteinvent
  endif
  CFLAGS += -Itelosb
  CFLAGS += -Ilib
  CFLAGS += -I$(TOSBOOT_DIR)
  CFLAGS += -I$(TOSBOOT_DIR)/lib
  CFLAGS += -I$(TOSBOOT_DIR)/msp430
  CFLAGS += -I$(TOSBOOT_DIR)/stm25p
  CFLAGS += -I$(TOSBOOT_DIR)/telosb 
  CFLAGS += -I$(DELUGE_DIR)
  CFLAGS += -I$(TOSBOOT_DIR)
  CFLAGS += -DNESC_BUILD_BINARY
  CFLAGS += -finline-limit=$(INLINE_LIMIT)
  CFLAGS += -Os

  POST_BUILD_EXTRA_DEPS += strip_iv
endif

strip_iv: FORCE
	@echo "    removing interrupt vector from binary"
	msp430-objcopy -j .text -j .data -O ihex $(BUILDDIR)/main.exe $(BUILDDIR)/main.ihex

include $(MAKERULES)
