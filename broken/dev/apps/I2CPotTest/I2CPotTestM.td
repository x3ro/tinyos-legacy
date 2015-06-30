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
includes sensorboard;

module I2CPotTestM
{
  provides {
    interface StdControl;
  }
  uses {
    interface Leds;
	interface I2CPot;
	interface StdControl as I2CControl;
  }
}

implementation
{

  // Frame variables
  char data;	/* data to be written */
  char state;   /* state of this module */
  char addr;    /* addr to be read/written */
  char pot;     /* pot select */

task void test1()
{
  int val =0;
  val = call I2CPot.writePot(TOS_MAG_POT_ADDR, 1, 88);
  if (!val) call Leds.redToggle();
}

task void test0()
{
  int val =0;
  val = call I2CPot.writePot(TOS_MAG_POT_ADDR, 0, 88);
  if (!val) call Leds.greenToggle();
}


  command result_t StdControl.init() {
    state = 0;
    call I2CControl.init();
    return SUCCESS;
  }

  command result_t StdControl.start() {
    int i = 0;
    call I2CControl.start();
    for (i=0; i<1; i++)
      //  post test1();
      post test0();
    return SUCCESS;
  }

  command result_t StdControl.stop() {
    call I2CControl.stop();
    return SUCCESS;
  }



  event result_t I2CPot.readPotDone(char in_data, bool result) {
    return SUCCESS;
  }

  event result_t I2CPot.writePotDone(bool result) {
    if (!result)  	
      call Leds.redToggle(); 
    //else call Leds.greenToggle();
    return SUCCESS;
  }

}










