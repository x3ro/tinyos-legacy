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
 * Date last modified:  $Revision: 1.1 $
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
  uint32_t gCurrentChannel;
  norace uint8_t gCurrentParameters[31];

  enum {
    IF = 150000,
    FREQ_MIN = 4194304,
    FREQ_MAX = 16751615
  };

  const uint32_t FRefTbl[9] = {2457600,
			       2106514,
			       1843200,
			       1638400,
			       1474560,
			       1340509,
			       1228800,
			       1134277,
			       1053257};
  
  const uint16_t CorTbl[9] = {1213,
			      1416,
			      1618,
			      1820,
			      2022,
			      2224,
			      2427,
			      2629,
			      2831};
  
  const uint16_t FSepTbl[9] = {0x1AA,
			       0x1F1,
			       0x238,
			       0x280,
			       0x2C7,
			       0x30E,
			       0x355,
			       0x39C,
			       0x3E3};
  
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
    //int freq = tunefreq;

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
    call HPLChipcon.write(CC1K_CURRENT,gCurrentParameters[29]);
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

  void cc1000SetFreq() {
    uint8_t i;
    // FREQA, FREQB, FSEP, CURRENT(RX), FRONT_END, POWER, PLL
    for (i = 1;i < 0x0d;i++) {
      call HPLChipcon.write(i,gCurrentParameters[i]);
    }

    // MATCH
    call HPLChipcon.write(CC1K_MATCH,gCurrentParameters[0x12]);

    chipcon_cal();

    return;

  }

  void cc1000SetModem() {
    call HPLChipcon.write(CC1K_MODEM2,gCurrentParameters[0x0f]);
    call HPLChipcon.write(CC1K_MODEM1,gCurrentParameters[0x10]);
    call HPLChipcon.write(CC1K_MODEM0,gCurrentParameters[0x11]);

    return;

  }

  /*
   * cc1000ComputeFreq(uint32_t desiredFreq);
   *
   * Compute an achievable frequency and the necessary CC1K parameters from
   * a given desired frequency (Hz). The function returns the actual achieved
   * channel frequency in Hz.
   *
   * This routine assumes the following:
   *  - Crystal Freq: 14.7456 MHz
   *  - LO Injection: High
   *  - Separation: 64 KHz
   *  - IF: 150 KHz
   * 
   * Approximate costs for this function:
   *  - ~870 bytes FLASH
   *  - ~32 bytes RAM
   *  - 9400 cycles
   */
  uint32_t cc1000ComputeFreq(uint32_t desiredFreq) {
    uint32_t ActualChannel = 0;
    uint32_t RXFreq = 0, TXFreq = 0;
    int32_t Offset = 0x7fffffff;
    uint16_t FSep = 0;
    uint8_t RefDiv = 0;
    uint8_t i;

    for (i = 0; i < 9; i++) {

      uint32_t NRef = ((desiredFreq + IF));
      uint32_t FRef = FRefTbl[i];
      uint32_t Channel = 0;
      uint32_t RXCalc = 0, TXCalc = 0;
      int32_t  diff;

      NRef = ((desiredFreq + IF) << 2) / FRef;
      if (NRef & 0x1) {
 	NRef++;
      }

      if (NRef & 0x2) {
	RXCalc = 16384 >> 1;
	Channel = FRef >> 1;
      }

      NRef >>= 2;

      RXCalc += (NRef * 16384) - 8192;
      if ((RXCalc < FREQ_MIN) || (RXCalc > FREQ_MAX)) 
	continue;
    
      TXCalc = RXCalc - CorTbl[i];
      if ((TXCalc < FREQ_MIN) || (TXCalc > FREQ_MAX)) 
	continue;

      Channel += (NRef * FRef);
      Channel -= IF;

      diff = Channel - desiredFreq;
      if (diff < 0)
	diff = 0 - diff;

      if (diff < Offset) {
	RXFreq = RXCalc;
	TXFreq = TXCalc;
	ActualChannel = Channel;
	FSep = FSepTbl[i];
	RefDiv = i + 6;
	Offset = diff;
      }

    }

    if (RefDiv != 0) {
      // FREQA
      gCurrentParameters[0x3] = (uint8_t)((RXFreq) & 0xFF);  // LSB
      gCurrentParameters[0x2] = (uint8_t)((RXFreq >> 8) & 0xFF);
      gCurrentParameters[0x1] = (uint8_t)((RXFreq >> 16) & 0xFF);  // MSB
      // FREQB
      gCurrentParameters[0x6] = (uint8_t)((TXFreq) & 0xFF); // LSB
      gCurrentParameters[0x5] = (uint8_t)((TXFreq >> 8) & 0xFF);
      gCurrentParameters[0x4] = (uint8_t)((TXFreq >> 16) & 0xFF);  // MSB
      // FSEP
      gCurrentParameters[0x8] = (uint8_t)((FSep) & 0xFF);  // LSB
      gCurrentParameters[0x7] = (uint8_t)((FSep >> 8) & 0xFF); //MSB

      if (ActualChannel < 500000000) {
	if (ActualChannel < 400000000) {
	// CURRENT (RX)
	  gCurrentParameters[0x9] = ((8 << CC1K_VCO_CURRENT) | (1 << CC1K_LO_DRIVE));
	// CURRENT (TX)
	  gCurrentParameters[0x1d] = ((9 << CC1K_VCO_CURRENT) | (1 << CC1K_PA_DRIVE));
	}
	else {
	// CURRENT (RX)
	  gCurrentParameters[0x9] = ((4 << CC1K_VCO_CURRENT) | (1 << CC1K_LO_DRIVE));
	// CURRENT (TX)
	  gCurrentParameters[0x1d] = ((8 << CC1K_VCO_CURRENT) | (1 << CC1K_PA_DRIVE));
	}
	// FRONT_END
	gCurrentParameters[0xa] = (1 << CC1K_IF_RSSI); 
	// MATCH
	gCurrentParameters[0x12] = (7 << CC1K_RX_MATCH);
      }
      else {
	// CURRENT (RX)
	  gCurrentParameters[0x9] = ((8 << CC1K_VCO_CURRENT) | (3 << CC1K_LO_DRIVE));
	// CURRENT (TX)
	  gCurrentParameters[0x1d] = ((15 << CC1K_VCO_CURRENT) | (3 << CC1K_PA_DRIVE));

	// FRONT_END
	gCurrentParameters[0xa] = ((1<<CC1K_BUF_CURRENT) | (2<<CC1K_LNA_CURRENT) | 
				 (1<<CC1K_IF_RSSI));
	// MATCH
	gCurrentParameters[0x12] = (2 << CC1K_RX_MATCH);

      }
      // PLL
      gCurrentParameters[0xc] = (RefDiv << CC1K_REFDIV);
    }

    gCurrentChannel = ActualChannel;
    return ActualChannel;

  }


  //
  // PUBLIC Module Functions
  //

  command result_t StdControl.init() {
    outp (0x41,TCCR3B);
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

    // Set default parameter values
    // POWER 0dbm
    gCurrentParameters[0xb] = ((8 << CC1K_PA_HIGHPOWER) | (0 << CC1K_PA_LOWPOWER)); 
    call HPLChipcon.write(CC1K_PA_POW, gCurrentParameters[0xb]);

    // LOCK Manchester Violation default
    gCurrentParameters[0xd] = (9 << CC1K_LOCK_SELECT);
    call HPLChipcon.write(CC1K_LOCK_SELECT, gCurrentParameters[0xd]);

    // Default modem values = 19.2 Kbps (38.4 kBaud), Manchester encoded
    // MODEM2
    gCurrentParameters[0xf] = 0;
    //call HPLChipcon.write(CC1K_MODEM2,gCurrentParameters[0xf]);
    // MODEM1
    gCurrentParameters[0x10] = ((3<<CC1K_MLIMIT) | (1<<CC1K_LOCK_AVG_MODE) | 
				(3<<CC1K_SETTLING) | (1<<CC1K_MODEM_RESET_N));
    //call HPLChipcon.write(CC1K_MODEM1,gCurrentParameters[0x10]);
    // MODEM0
    gCurrentParameters[0x11] = ((5<<CC1K_BAUDRATE) | (1<<CC1K_DATA_FORMAT) | 
				(1<<CC1K_XOSC_FREQ));
    //call HPLChipcon.write(CC1K_MODEM0,gCurrentParameters[0x11]);

    cc1000SetModem();
    // FSCTRL
    gCurrentParameters[0x13] = (1 << CC1K_FS_RESET_N);
    call HPLChipcon.write(CC1K_FSCTRL,gCurrentParameters[0x13]);

    // HIGH Side LO
    gCurrentParameters[0x1e] = TRUE;


    // Program registers w/ default freq and calibrate
#ifdef CC1K_DEF_FREQ
    call CC1000Control.TuneManual(CC1K_DEF_FREQ);
#else
    call CC1000Control.TunePreset(CC1K_DEF_PRESET);     // go to default tune frequency
#endif
    return SUCCESS;
  }



  command result_t CC1000Control.TunePreset(uint8_t freq) {
    int i;

    for (i=1;i < 31 /*0x14*/;i++) {
      //call HPLChipcon.write(i,PRG_RDB(&CC1K_Params[freq][i]));
      gCurrentParameters[i] = PRG_RDB(&CC1K_Params[freq][i]);
    }
    cc1000SetFreq();

    return SUCCESS;
  }

  command uint32_t CC1000Control.TuneManual(uint32_t DesiredFreq) {
    uint32_t actualFreq;

    actualFreq = cc1000ComputeFreq(DesiredFreq);

    cc1000SetFreq();

    return actualFreq;
  }

  async command result_t CC1000Control.TxMode() {
    // MAIN register to TX mode
    call HPLChipcon.write(CC1K_MAIN,
			  ((1<<CC1K_RXTX) | (1<<CC1K_F_REG) | (1<<CC1K_RX_PD) | 
			   (1<<CC1K_RESET_N)));
    // Set the TX mode VCO Current
    call HPLChipcon.write(CC1K_CURRENT,gCurrentParameters[29]);
    TOSH_uwait(250);
    call HPLChipcon.write(CC1K_PA_POW,gCurrentParameters[0xb] /*rfpower*/);
    TOSH_uwait(20);
    return SUCCESS;
  }

  async command result_t CC1000Control.RxMode() {
    // MAIN register to RX mode
    // Powerup Freqency Synthesizer and Receiver
    call HPLChipcon.write(CC1K_CURRENT,gCurrentParameters[0x09]);
    call HPLChipcon.write(CC1K_PA_POW,0x00); // turn off power amp
    call HPLChipcon.write(CC1K_MAIN,
			  ((1<<CC1K_TX_PD) | (1<<CC1K_RESET_N)));
    // Sex the RX mode VCO Current
    TOSH_uwait(125);
    return SUCCESS;
  }

  command result_t CC1000Control.BIASOff() {
    // MAIN register to SLEEP mode
    call HPLChipcon.write(CC1K_MAIN,
			  ((1<<CC1K_RX_PD) | (1<<CC1K_TX_PD) | 
			   (1<<CC1K_FS_PD) | //(1<<CC1K_BIAS_PD) |
			   (1<<CC1K_RESET_N)));
								 
    return SUCCESS;
  }

  command result_t CC1000Control.BIASOn() {
    //call CC1000Control.RxMode();
    call HPLChipcon.write(CC1K_MAIN,
			  ((1<<CC1K_RX_PD) | (1<<CC1K_TX_PD) | 
			   (1<<CC1K_FS_PD) | 
			   (1<<CC1K_RESET_N)));
    
    //TOSH_uwait(200 /*500*/);
    return SUCCESS;
  }


  command result_t StdControl.stop() {
    // MAIN register to power down mode. Shut everything off
    call HPLChipcon.write(CC1K_MAIN,
			  ((1<<CC1K_RX_PD) | (1<<CC1K_TX_PD) | 
			   (1<<CC1K_FS_PD) | (1<<CC1K_CORE_PD) | (1<<CC1K_BIAS_PD) |
			   (1<<CC1K_RESET_N)));

    call HPLChipcon.write(CC1K_PA_POW,0x00);  // turn off rf amp
    return SUCCESS;
  }

  command result_t StdControl.start() {
    // wake up xtal osc
    call HPLChipcon.write(CC1K_MAIN,
			  ((1<<CC1K_RX_PD) | (1<<CC1K_TX_PD) | 
			   (1<<CC1K_FS_PD) | (1<<CC1K_BIAS_PD) |
			   (1<<CC1K_RESET_N)));

    //TOSH_uwait(2000);
//    call CC1000Control.RxMode();

    return SUCCESS;
  }


  command result_t CC1000Control.SetRFPower(uint8_t power) {
    gCurrentParameters[0xb] = power;
    //rfpower = power;
    //call HPLChipcon.write(CC1K_PA_POW,rfpower); // Set power amp value
    return SUCCESS;
  }

  command uint8_t CC1000Control.GetRFPower() {
    return gCurrentParameters[0xb]; //rfpower;
  }

  command result_t CC1000Control.SelectLock(uint8_t Value) {
    //LockVal = Value;
    gCurrentParameters[0xd] = (Value << CC1K_LOCK_SELECT);
    return call HPLChipcon.write(CC1K_LOCK,(Value << CC1K_LOCK_SELECT));
  }

  command uint8_t CC1000Control.GetLock() {
    uint8_t retVal;
    retVal = (uint8_t)call HPLChipcon.GetLOCK(); 
    return retVal;
  }

  command bool CC1000Control.GetLOStatus() {

    return gCurrentParameters[0x1e];

  }

}


