/*									tab:4
 *
 *
 * "Copyright (c) 2000-2002 The Regents of the University  of California.  
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY OF
 * CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 *
 */
/*									tab:4
 *  IMPORTANT: READ BEFORE DOWNLOADING, COPYING, INSTALLING OR USING.  By
 *  downloading, copying, installing or using the software you agree to
 *  this license.  If you do not agree to this license, do not download,
 *  install, copy or use the software.
 *
 *  Intel Open Source License 
 *
 *  Copyright (c) 2002 Intel Corporation 
 *  All rights reserved. 
 *  Redistribution and use in source and binary forms, with or without
 *  modification, are permitted provided that the following conditions are
 *  met:
 * 
 *	Redistributions of source code must retain the above copyright
 *  notice, this list of conditions and the following disclaimer.
 *	Redistributions in binary form must reproduce the above copyright
 *  notice, this list of conditions and the following disclaimer in the
 *  documentation and/or other materials provided with the distribution.
 *      Neither the name of the Intel Corporation nor the names of its
 *  contributors may be used to endorse or promote products derived from
 *  this software without specific prior written permission.
 *  
 *  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 *  ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 *  LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
 *  PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE INTEL OR ITS
 *  CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 *  EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 *  PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 *  PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 *  LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 *  NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 *  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * 
 */
/*
 *
 * Authors:	        Joe Polastre
 *
 * $Id: MicaWbADCM.td,v 1.4 2002/08/07 23:12:27 idgay Exp $
 */

module MicaWbADCM
{
  provides {
    interface StdControl;
    interface ADC[uint8_t port];
  }
  uses interface I2CPacket;
}
implementation
{

  enum {IDLE, SINGLE_PICK_CHANNEL, SINGLE_GET_SAMPLE, SINGLE_GOT_SAMPLE,
	MULT_PICK_CHANNEL};

  char state;       /* current state of the i2c request */
  char addr;        /* destination address */
  char condition;   /* set the condition command byte */
  char flags;       /* flags set on the I2C packets */
  uint16_t value;   /* value of the incoming ADC reading */

  command result_t StdControl.init() {
    state = IDLE;
    return SUCCESS;
  }

  command result_t StdControl.power(char mode) {
    return SUCCESS;
  }

  /* get a single reading from id */
  command result_t ADC.getData[uint8_t id]() {
    if (state == IDLE)
    {
      char channel = id;
      state = SINGLE_PICK_CHANNEL;
      /* figure out which channel is to be set */
      if (channel == 0)
        condition = 8;
      else if (channel == 1)
	condition = 12;
      else if (channel == 2)
	condition = 9;
      else if (channel == 3)
	condition = 13;
      else if (channel == 4)
	condition = 10;
      else if (channel == 5)
	condition = 14;
      else if (channel == 6)
	condition = 11;
      else if (channel == 7)
	condition = 15;
      else
	{
	  /* invalid channel number specified */
	  state = IDLE;
	  return FAIL;
	}
      /* shift the channel and single-ended input bits over */
      condition = (condition << 4) & 0xF0;
      /* don't send the stop condition */
      flags = 0x00;
      /* tell the ADC to start converting */
      if ((call I2CPacket.writePacket(1, (char*)(&condition), flags)) == FAIL)
	{
	  state = IDLE;
	  return FAIL;
	}
      return SUCCESS;
    }
    return FAIL;
  }

  /* not yet implemented */
  command result_t ADC.getContinuousData[uint8_t id]() {
    return FAIL;
  }

  event result_t I2CPacket.readPacketDone(char length, char* data) {
    if (state == SINGLE_GET_SAMPLE)
    {
      state = SINGLE_GOT_SAMPLE;
      value = (data[0] << 8) & 0x0f00;
      value += (data[1] & 0xff);
      state = IDLE;
      signal ADC.dataReady(value);
    }
    return SUCCESS;
  }

  event result_t I2CPacket.writePacketDone(bool result) {
    if (state == SINGLE_PICK_CHANNEL)
    {
      state = SINGLE_GET_SAMPLE;
      flags = 0x03;
      if ((call I2CPacket.readPacket(2, flags)) == 0)
	{
	  /* reading from the bus failed */
	  state = IDLE;
	  signal ADC.dataReady(-1);
	}
      return SUCCESS;
    }
    return SUCCESS;
  }

}
