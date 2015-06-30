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
 * Authors:		Jaein Jeong, Phil Buonadonna
 * Date last modified:  $Revision: 1.1.1.1 $
 *
 * This module provides the CONTROL functionality for the Chipcon1000 series radio.
 * It exports both a standard control interface and a custom interface to control
 * CC1000 operation.
 */

module CC1000ControlM {
  provides {
    interface StdControl;
    interface CC1000Control;
  }
  uses {
    interface HPLCC1000 as HPLChipcon;
  }
}
implementation
{
  uint8_t tunefreq;
  uint8_t rfpower;
  uint8_t LockVal;

  //
  // PRIVATE Module functions
  //

  ///************************************************************/
  ///* Function: chipcon_cal                                    */
  ///* Description: places the chipcon radio in calibrate mode  */
  ///*                                                          */
  ///************************************************************/

  result_t chipcon_cal()
  {
    //int i;
    int freq = tunefreq;

    call HPLChipcon.write(CC1K_PA_POW,0x00);  // turn off rf amp
    call HPLChipcon.write(CC1K_TEST4,0x3f);   // chip rate >= 38.4kb

    // RX - configure main freq A
    call HPLChipcon.write(CC1K_MAIN,
			  ((1<<CC1K_TX_PD) | (1<<CC1K_RESET_N)));
    //TOSH_uwait(2000);

    // start cal
    call HPLChipcon.write(CC1K_CAL,
			  ((1<<CC1K_CAL_START) | 
			   (1<<CC1K_CAL_WAIT) | (6<<CC1K_CAL_ITERATE)));
#if 0
    for (i=0;i<34;i++)  // need 34 ms delay
      TOSH_uwait(1000);
#endif
    while (((call HPLChipcon.read(CC1K_CAL)) & (1<<CC1K_CAL_COMPLETE)) == 0);

    //exit cal mode
    call HPLChipcon.write(CC1K_CAL,
			  ((1<<CC1K_CAL_WAIT) | (6<<CC1K_CAL_ITERATE)));


    // TX - configure main freq B
    call HPLChipcon.write(CC1K_MAIN,
			  ((1<<CC1K_RXTX) | (1<<CC1K_F_REG) | (1<<CC1K_RX_PD) | 
			   (1<<CC1K_RESET_N)));
    // Set TX current
    call HPLChipcon.write(CC1K_CURRENT,PRG_RDB(&CC1K_Params[freq][29]));
    call HPLChipcon.write(CC1K_PA_POW,0x00);
    //TOSH_uwait(2000);

    // start cal
    call HPLChipcon.write(CC1K_CAL,
			  ((1<<CC1K_CAL_START) | 
			   (1<<CC1K_CAL_WAIT) | (6<<CC1K_CAL_ITERATE)));
#if 0
    for (i=0;i<28;i++)  // need 28 ms delay
      TOSH_uwait(1000);
#endif
    while (((call HPLChipcon.read(CC1K_CAL)) & (1<<CC1K_CAL_COMPLETE)) == 0);

    //exit cal mode
    call HPLChipcon.write(CC1K_CAL,
			  ((1<<CC1K_CAL_WAIT) | (6<<CC1K_CAL_ITERATE)));
    
    //TOSH_uwait(200);

    return SUCCESS;
  }

  //
  // PUBLIC Module Functions
  //

  command result_t StdControl.init() {

    call HPLChipcon.init();

    // wake up xtal and reset unit
    call HPLChipcon.write(CC1K_MAIN,
			  ((1<<CC1K_RX_PD) | (1<<CC1K_TX_PD) | 
			   (1<<CC1K_FS_PD) | (1<<CC1K_BIAS_PD))); 
    // clear reset.
    call HPLChipcon.write(CC1K_MAIN,
			  ((1<<CC1K_RX_PD) | (1<<CC1K_TX_PD) | 
			   (1<<CC1K_FS_PD) | (1<<CC1K_BIAS_PD) |
			   (1<<CC1K_RESET_N))); 
    // reset wait time
    TOSH_uwait(2000);        

    // Program registers w/ default freq and calibrate
    call CC1000Control.Tune(CC1K_DEFAULT_FREQ);     // go to default tune frequency

    return SUCCESS;
  }

  command result_t CC1000Control.Tune(uint8_t freq) {
    int i;
    tunefreq = freq;
    rfpower = PRG_RDB(&CC1K_Params[freq][0xb]); // Record default RF power
    LockVal = PRG_RDB(&CC1K_Params[freq][0xd]); // Record default LOCK value

    for (i=1;i<0x14;i++)
      call HPLChipcon.write(i,PRG_RDB(&CC1K_Params[freq][i]));

    call HPLChipcon.write(CC1K_PRESCALER,PRG_RDB(&CC1K_Params[freq][0x1c]));

    chipcon_cal();

    //call CC1000Control.RxMode();

    return SUCCESS;
  }

  command result_t CC1000Control.TxMode() {
    // MAIN register to TX mode
    call HPLChipcon.write(CC1K_MAIN,
			  ((1<<CC1K_RXTX) | (1<<CC1K_F_REG) | (1<<CC1K_RX_PD) | 
			   (1<<CC1K_RESET_N)));
    // Set the TX mode VCO Current
    call HPLChipcon.write(CC1K_CURRENT,PRG_RDB(&CC1K_Params[tunefreq][29]));
    TOSH_uwait(250);
    call HPLChipcon.write(CC1K_PA_POW,rfpower);
    TOSH_uwait(20);
    return SUCCESS;
  }

  command result_t CC1000Control.RxMode() {
    // MAIN register to RX mode
    // Powerup Freqency Synthesizer and Receiver
    call HPLChipcon.write(CC1K_MAIN,
			  ((1<<CC1K_TX_PD) | (1<<CC1K_RESET_N)));
    // Sex the RX mode VCO Current
    call HPLChipcon.write(CC1K_CURRENT,PRG_RDB(&CC1K_Params[tunefreq][0x09]));
    call HPLChipcon.write(CC1K_PA_POW,0x00); // turn off power amp
    TOSH_uwait(250);
    return SUCCESS;
  }

  command result_t CC1000Control.BIASOff() {
    // MAIN register to SLEEP mode
    call HPLChipcon.write(CC1K_MAIN,
			  ((1<<CC1K_RX_PD) | (1<<CC1K_TX_PD) | 
			   (1<<CC1K_FS_PD) | (1<<CC1K_BIAS_PD) |
			   (1<<CC1K_RESET_N)));
								 
    return SUCCESS;
  }

  command result_t CC1000Control.BIASOn() {
    //call CC1000Control.RxMode();
    call HPLChipcon.write(CC1K_MAIN,
			  ((1<<CC1K_RX_PD) | (1<<CC1K_TX_PD) | 
			   (1<<CC1K_FS_PD) | 
			   (1<<CC1K_RESET_N)));
    
    TOSH_uwait(200 /*500*/);
    return SUCCESS;
  }


  command result_t StdControl.stop() {
    // MAIN register to power down mode. Shut everything off
    call HPLChipcon.write(CC1K_MAIN,
			  ((1<<CC1K_RX_PD) | (1<<CC1K_TX_PD) | 
			   (1<<CC1K_FS_PD) | (1<<CC1K_CORE_PD) | (1<<CC1K_BIAS_PD) |
			   (1<<CC1K_RESET_N)));

    return SUCCESS;
  }

  command result_t StdControl.start() {
    // wake up xtal osc
    call HPLChipcon.write(CC1K_MAIN,
			  ((1<<CC1K_RX_PD) | (1<<CC1K_TX_PD) | 
			   (1<<CC1K_FS_PD) | (1<<CC1K_BIAS_PD) |
			   (1<<CC1K_RESET_N)));

    TOSH_uwait(2000);
//    call CC1000Control.RxMode();

    return SUCCESS;
  }


  command result_t CC1000Control.SetRFPower(uint8_t power) {
    rfpower = power;
    //call HPLChipcon.write(CC1K_PA_POW,rfpower); // Set power amp value
    return SUCCESS;
  }

  command uint8_t CC1000Control.GetRFPower() {
    return rfpower;
  }

  command result_t CC1000Control.SelectLock(uint8_t Value) {
    LockVal = Value;
    return call HPLChipcon.write(CC1K_LOCK,(LockVal<<CC1K_LOCK_SELECT));
  }

  command uint8_t CC1000Control.GetLock() {
    uint8_t retVal;
    retVal = (uint8_t)call HPLChipcon.GetLOCK(); 
    return retVal;
  }

  command bool CC1000Control.GetLOStatus() {

    return PRG_RDB(&CC1K_Params[tunefreq][0x1e]);

  }

}


