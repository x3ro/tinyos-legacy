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
 * $Id: MicaWbSwitchM.td,v 1.3 2002/08/07 23:12:27 idgay Exp $
 */

module MicaWbSwitchM
{
  provides {
    interface StdControl;
    interface Switch;
  }
  uses interface I2CPacket;
}
implementation
{

  enum { GET_SWITCH, SET_SWITCH, SET_SWITCH_ALL, 
         SET_SWITCH_GET, IDLE};

  char sw_state; /* current state of the switch */
  char state;    /* current state of the i2c request */
  char addr;     /* destination address */
  char position;
  char value;

  command result_t StdControl.init() {
    state = IDLE;
    return SUCCESS;
  }

  command result_t StdControl.power(char mode) {
    return SUCCESS;
  }

  command result_t Switch.get() {
    if (state == IDLE)
    {
      state = GET_SWITCH;
      return call I2CPacket.readPacket(1, 0x01);
    }
    return FAIL;
  }

  command result_t Switch.set(char l_position, char l_value) {
    if (state == IDLE)
    {
      state = SET_SWITCH_GET;
      value = l_value;
      position = l_position;
      return call I2CPacket.readPacket(1,0x01);
    }
    return FAIL;
  }

  command result_t Switch.setAll(char value) {
    if (state == IDLE)
    {
      state = SET_SWITCH_ALL;
      sw_state = value;

      return call I2CPacket.writePacket(1, (char*)(&sw_state), 0x01);
    }
    return FAIL;
  }

  event result_t I2CPacket.writePacketDone(bool result) {
    if (state == SET_SWITCH)
    {
      state = IDLE;
      signal Switch.setDone(result);
    }
    else if (state == SET_SWITCH_ALL) {
      state = IDLE;
      signal Switch.setAllDone(result);
    }
    return SUCCESS;
  }

  event result_t I2CPacket.readPacketDone(char length, char* data) {
    if (state == GET_SWITCH)
    {
      if (length != 1)
      {
	state = IDLE;
	signal Switch.getDone(0);
	return SUCCESS;
      }
      else {
	state = IDLE;
	signal Switch.getDone(data[0]);
	return SUCCESS;
      }
    }
    if (state == SET_SWITCH_GET)
    {
      if (length != 1)
      {
	state = IDLE;
	signal Switch.getDone(0);
	return SUCCESS;
      }

      sw_state = data[0];

      if (position == 1) {
	sw_state = sw_state & 0xFE;
	sw_state = sw_state | value;
      }
      if (position == 2) {
	sw_state = sw_state & 0xFD;
	sw_state = sw_state | (value << 1);
      }
      if (position == 3) {
	sw_state = sw_state & 0xFB;
	sw_state = sw_state | (value << 2);
      }
      if (position == 4) {
	sw_state = sw_state & 0xF7;
	sw_state = sw_state | (value << 3);
      }
      if (position == 5) {
	sw_state = sw_state & 0xEF;
	sw_state = sw_state | (value << 4);
      }
      if (position == 6) {
	sw_state = sw_state & 0xDF;
	sw_state = sw_state | (value << 5);
      }
      if (position == 7) {
	sw_state = sw_state & 0xBF;
	sw_state = sw_state | (value << 6);
      }
      if (position == 8) {
	sw_state = sw_state & 0x7F;
	sw_state = sw_state | (value << 7);
      }
      data[0] = sw_state;
      state = SET_SWITCH;
      call I2CPacket.writePacket(1, (char*)&sw_state, 0x01);
      return SUCCESS;
    } 
    return SUCCESS;
  }

}
