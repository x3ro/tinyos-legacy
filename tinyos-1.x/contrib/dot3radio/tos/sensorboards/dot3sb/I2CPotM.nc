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
 * Authors:		Alec Woo
 * Date last modified:  7/23/02
 *
 */

module I2CPotM
{
  provides {
    interface StdControl;
    interface I2CPot;
  }
  uses {
    interface I2C;
    interface Leds;
	interface StdControl as I2CControl;
  }
}

implementation
{

  /* state of the i2c request */
  enum {IDLE=0,
	READ_POT_START=11,
	READ_COMMAND = 13,
	READ_COMMAND_2 = 14,
	READ_COMMAND_3 = 15,
	READ_COMMAND_4 = 16,
	READ_COMMAND_5 = 17,
	READ_POT_READING_DATA = 18,
        READ_FAIL = 19,
	WRITE_POT_START = 30,
	WRITE_COMMAND = 31,
	WRITE_COMMAND_2 = 32,
	WRITING_TO_POT = 33,
	WRITE_POT_STOP = 40,
        WRITE_FAIL = 49,
	READ_POT_STOP = 41
	};	

  // Frame variables
  char data;	/* data to be written */
  char state;   /* state of this module */
  char addr;    /* addr to be read/written */
  char pot;     /* pot select */

  command result_t StdControl.init() {
    call I2CControl.init();
    state = IDLE;
    return SUCCESS;
  }

  command result_t StdControl.start() {
    return SUCCESS;
  }

  command result_t StdControl.stop() {
    return SUCCESS;
  }

  /* writes the new pot setting over the I2C bus */
  command result_t I2CPot.writePot(char line_addr, 
	char pot_addr, char in_data){	

    if (state == IDLE)
    {
      /*  reset variables  */
      addr = line_addr;
      pot = pot_addr;
      data = in_data;
      state = WRITE_POT_START;
      if (call I2C.sendStart()){
	return SUCCESS;
      }else{
	state = IDLE;
	return FAIL;
      }
    } else {
      return FAIL;
    }
  }
  
  command result_t I2CPot.readPot(char line_addr, char pot_addr){
    if (state == IDLE)
    {
      addr = line_addr;
      pot = pot_addr;
      state = READ_POT_START;
      if (call I2C.sendStart()){
	return SUCCESS;
      }else{
	state = IDLE;
	return FAIL;
      }
    }
    else {
      return FAIL;
    }
  }


  /* notification that the start symbol was sent */
  event result_t I2C.sendStartDone() {
    char ret;

    if(state == WRITE_POT_START){
      state = WRITE_COMMAND;
      ret = call I2C.write(0x58 | ((addr << 1) & 0x06));
    }
    else if (state == READ_POT_START){
      state = READ_COMMAND;
      call I2C.write(0x59 | ((addr << 1) & 0x06));
    }
    return SUCCESS;
  }

  /* notification that the stop symbol was sent */
  event result_t I2C.sendEndDone() {

    if (state == WRITE_POT_STOP){
      state = IDLE;
      signal I2CPot.writePotDone(SUCCESS);
    }
    else if (state == READ_POT_STOP) {
      state = IDLE;
      signal I2CPot.readPotDone(data, SUCCESS);
    }
    else if ( state == READ_FAIL ){
      state = IDLE ;
      signal I2CPot.readPotDone(data, FAIL);
    }
    else if ( state == WRITE_FAIL ) {
      state = IDLE ;
      signal I2CPot.writePotDone(FAIL);
    }

    return SUCCESS;
  }

  /* notification of a byte sucessfully written to the bus */
  event result_t I2C.writeDone(bool result) {

    if (result == FAIL){
      state = WRITE_FAIL;
      call I2C.sendEnd();
      return FAIL ;
    }
    if (state== WRITING_TO_POT) {
      state = WRITE_POT_STOP;
      call I2C.sendEnd();
      return 0;
    } else if (state == WRITE_COMMAND) {
      state = WRITE_COMMAND_2;
      call I2C.write(0 | ((pot << 7) & 0x80));
    } else if (state ==WRITE_COMMAND_2){
      state = WRITING_TO_POT;
      call I2C.write(data);
    } else if (state ==READ_COMMAND) {
      state = READ_POT_READING_DATA;
      call I2C.read(0 | ((pot << 7) & 0x80));
    }

    return SUCCESS;
  }

  /* read a byte off the bus and add it to the packet */
  event result_t I2C.readDone(char in_data) {
    if (state == IDLE){
      data = 0;
      return FAIL;
    }
    if (state == READ_POT_READING_DATA){
      state = READ_POT_STOP;
      data = in_data;
      call I2C.sendEnd();
      return FAIL; 
    }
    return SUCCESS;
  }

  default event result_t I2CPot.readPotDone(char in_data, bool result) {
    return SUCCESS;
  }

  default event result_t I2CPot.writePotDone(bool result) {
    return SUCCESS;
  }

}










