// $Id: CC2420ControlM.nc,v 1.3 2005/04/19 02:56:03 husq Exp $

/*									tab:4
 * "Copyright (c) 2000-2003 The Regents of the University  of California.  
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
 * Copyright (c) 2002-2003 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */
/*
 *
 * Authors:		Alan Broad, Joe Polastre
 * Date last modified:  $Revision: 1.3 $
 *
 * This module provides the CONTROL functionality for the 
 * Chipcon2420 series radio. It exports both a standard control 
 * interface and a custom interface to control CC2420 operation.
 */

/**
 * @author Alan Broad, Crossbow
 * @author Joe Polastre
 */
/*
 *
 * $Log: CC2420ControlM.nc,v $
 * Revision 1.3  2005/04/19 02:56:03  husq
 * Import the micazack and CC2420RadioAck
 *
 * Revision 1.2  2005/03/02 22:34:16  jprabhu
 * Added Log-tag for capturing changes in files.
 *
 *
 */


includes byteorder;

module CC2420ControlM {
  provides {
    interface StdControl;
    interface CC2420Control;
  }
  uses {
    interface StdControl as HPLChipconControl;
    interface HPLCC2420 as HPLChipcon;
    interface HPLCC2420RAM as HPLChipconRAM;
  }
}
implementation
{
  #define XOSC_TIMEOUT 200     //times to chk if CC2420 crystal is on

  norace uint16_t gCurrentParameters[14];
  uint8_t TOS_CC2420_CHANNEL = CC2420_DEF_CHANNEL;
  uint8_t TOS_CC2420_TXPOWER = CC2420_TXPOWER;  

   /************************************************************************
   * SetRegs
   *  - Configure CC2420 registers with current values
   *  - Readback 1st register written to make sure electrical connection OK
   *************************************************************************/
  bool SetRegs(){
    uint16_t data;
	      
    call HPLChipcon.write(CC2420_MAIN,gCurrentParameters[CP_MAIN]);   		    
    call HPLChipcon.write(CC2420_MDMCTRL0, gCurrentParameters[CP_MDMCTRL0]);
    data = call HPLChipcon.read(CC2420_MDMCTRL0);
    if (data != gCurrentParameters[CP_MDMCTRL0]) return FALSE;
    
    call HPLChipcon.write(CC2420_MDMCTRL1, gCurrentParameters[CP_MDMCTRL1]);
    call HPLChipcon.write(CC2420_RSSI, gCurrentParameters[CP_RSSI]);
    call HPLChipcon.write(CC2420_SYNCWORD, gCurrentParameters[CP_SYNCWORD]);
    call HPLChipcon.write(CC2420_TXCTRL, gCurrentParameters[CP_TXCTRL]);
    call HPLChipcon.write(CC2420_RXCTRL0, gCurrentParameters[CP_RXCTRL0]);
    call HPLChipcon.write(CC2420_RXCTRL1, gCurrentParameters[CP_RXCTRL1]);
    call HPLChipcon.write(CC2420_FSCTRL, gCurrentParameters[CP_FSCTRL]);

    call HPLChipcon.write(CC2420_SECCTRL0, gCurrentParameters[CP_SECCTRL0]);
    call HPLChipcon.write(CC2420_SECCTRL1, gCurrentParameters[CP_SECCTRL1]);
    call HPLChipcon.write(CC2420_IOCFG0, gCurrentParameters[CP_IOCFG0]);
    call HPLChipcon.write(CC2420_IOCFG1, gCurrentParameters[CP_IOCFG1]);

    call HPLChipcon.cmd(CC2420_SFLUSHTX);    //flush Tx fifo
    call HPLChipcon.cmd(CC2420_SFLUSHRX);
 
    return TRUE;
  
  }

  /*************************************************************************
   * Init CC2420 radio:
   *
   *************************************************************************/
  command result_t StdControl.init() {
      
    call HPLChipconControl.init();
// Set default parameters
    gCurrentParameters[CP_MAIN] = 0xf800;
    gCurrentParameters[CP_MDMCTRL0] = ((CC2420_ADDRDECODE << CC2420_MDMCTRL0_ADRDECODE) | 
//    gCurrentParameters[CP_MDMCTRL0] = ((0 << CC2420_MDMCTRL0_ADRDECODE) | 
       (2 << CC2420_MDMCTRL0_CCAHIST) | (3 << CC2420_MDMCTRL0_CCAMODE)  | 
       (1 << CC2420_MDMCTRL0_AUTOCRC) | (2 << CC2420_MDMCTRL0_PREAMBL));

    gCurrentParameters[CP_MDMCTRL1] = 20 << CC2420_MDMCTRL1_CORRTHRESH;

    gCurrentParameters[CP_RSSI] =     0xE080;  //CCA threshold,
    gCurrentParameters[CP_SYNCWORD] = 0xA70F;
    gCurrentParameters[CP_TXCTRL] = ((1 << CC2420_TXCTRL_BUFCUR) | 
       (1 << CC2420_TXCTRL_TURNARND) | (3 << CC2420_TXCTRL_PACUR) | 
       (1 << CC2420_TXCTRL_PADIFF) | (TOS_CC2420_TXPOWER << CC2420_TXCTRL_PAPWR));
   
    gCurrentParameters[CP_RXCTRL0] = ((1 << CC2420_RXCTRL0_BUFCUR) | 
       (2 << CC2420_RXCTRL0_MLNAG) | (3 << CC2420_RXCTRL0_LOLNAG) | 
       (2 << CC2420_RXCTRL0_HICUR) | (1 << CC2420_RXCTRL0_MCUR) | 
       (1 << CC2420_RXCTRL0_LOCUR));

    gCurrentParameters[CP_RXCTRL1]  = ((1 << CC2420_RXCTRL1_LOLOGAIN)   | (1 << CC2420_RXCTRL1_HIHGM    ) |
	                                   (1 << CC2420_RXCTRL1_LNACAP)     | (1 << CC2420_RXCTRL1_RMIXT    ) |
									   (1 << CC2420_RXCTRL1_RMIXV)      | (2 << CC2420_RXCTRL1_RMIXCUR  ) );
									    
    
	gCurrentParameters[CP_FSCTRL]   = ((1 << CC2420_FSCTRL_LOCK)        | ((357+5*(TOS_CC2420_CHANNEL-11)) << CC2420_FSCTRL_FREQ));


    gCurrentParameters[CP_SECCTRL0] = ((1 << CC2420_SECCTRL0_CBCHEAD)  |
	                                   (1 << CC2420_SECCTRL0_SAKEYSEL)  | (1 << CC2420_SECCTRL0_TXKEYSEL) |
									   (1 << CC2420_SECCTRL0_SECM ) );


    gCurrentParameters[CP_SECCTRL1] = 0;
    gCurrentParameters[CP_BATTMON]  = 0;
    //gCurrentParameters[CP_IOCFG0]   = (((TOSH_DATA_LENGTH + 2) << CC2420_IOCFG0_FIFOTHR) | (1 <<CC2420_IOCFG0_FIFOPPOL)) ;
	//set fifop threshold to greater than size of tos msg, fifop goes active at end of msg
	//FIFOP INterrupt active LOW
	gCurrentParameters[CP_IOCFG0]   = (((CC2420_RXFIFO_THRESHOLD) << CC2420_IOCFG0_FIFOTHR) | (CC2420_RXFIFO_PPOL <<CC2420_IOCFG0_FIFOPPOL)) ;

    gCurrentParameters[CP_IOCFG1]   =  0;

    return SUCCESS;
  }


  command result_t StdControl.stop() {
    return call HPLChipconControl.stop();
  }

/******************************************************************************
 * Start CC2420 radio:
 * -Turn on 1.8V voltage regulator, wait for power-up, 0.6msec
 * -Release reset line
 * -Enable CC2420 crystal,          wait for stabilization, 0.9 msec
 *
 ******************************************************************************/

  command result_t StdControl.start() {
    result_t status;

    call HPLChipconControl.start();
    //turn on power
    TOSH_SET_CC_VREN_PIN();    //turn-on CC2420 1.8V supply and wait
    TOSH_uwait(1800);
    // toggle reset	        
    TOSH_CLR_CC_RSTN_PIN();
    TOSH_uwait(10);
    TOSH_SET_CC_RSTN_PIN();
    TOSH_uwait(10);
    // turn on crystal, takes about 860 usec, 
    // chk CC2420 status reg for stablize
    status = call CC2420Control.OscillatorOn();
    //set freq, load regs
    status = SetRegs() && status;
    status = status && call CC2420Control.setShortAddress(TOS_LOCAL_ADDRESS);
    status = status && call CC2420Control.TunePreset(TOS_CC2420_CHANNEL);
    call CC2420Control.RxMode();            //radio in receive mode	
    call HPLChipcon.enableFIFOP();          //enable interrupt when pkt rcvd
    return status;
  }

  /*************************************************************************
   * TunePreset
   * -Set CC2420 channel
   * Valid channel values are 11 through 26.
   * The channels are calculated by:
   *  Freq = 2405 + 5(k-11) MHz for k = 11,12,...,26
   * chnl requested 802.15.4 channel 
   * return Status of the tune operation
   *************************************************************************/
  command result_t CC2420Control.TunePreset(uint8_t chnl) {
    int fsctrl;
    
    fsctrl = 357 + 5*(chnl-11);
    gCurrentParameters[CP_FSCTRL] = (gCurrentParameters[CP_FSCTRL] & 0xfc00) | (fsctrl << CC2420_FSCTRL_FREQ);
    call HPLChipcon.write(CC2420_FSCTRL, gCurrentParameters[CP_FSCTRL]);
    return SUCCESS;
  }

  /*************************************************************************
   * TuneManual
   * Tune the radio to a given frequency. Frequencies may be set in
   * 1 MHz steps between 2400 MHz and 2483 MHz
   * 
   * Desiredfreq The desired frequency, in MHz.
   * Return Status of the tune operation
   *************************************************************************/
  command result_t CC2420Control.TuneManual(uint16_t DesiredFreq) {
   int fsctrl;
   
   fsctrl = DesiredFreq - 2048;
   gCurrentParameters[CP_FSCTRL] = (gCurrentParameters[CP_FSCTRL] & 0xfc00) | (fsctrl << CC2420_FSCTRL_FREQ);
   call HPLChipcon.write(CC2420_FSCTRL, gCurrentParameters[CP_FSCTRL]);
   return SUCCESS;
  }

  /*************************************************************************
   * TxMode
   * Shift the CC2420 Radio into transmit mode.
   * return SUCCESS if the radio was successfully switched to TX mode.
   *************************************************************************/
  async command result_t CC2420Control.TxMode() {
    call HPLChipcon.cmd(CC2420_STXON);
    return SUCCESS;
  }

  /*************************************************************************
   * TxModeOnCCA
   * Shift the CC2420 Radio into transmit mode when the next clear channel
   * is detected.
   *
   * return SUCCESS if the transmit request has been accepted
   *************************************************************************/
  async command result_t CC2420Control.TxModeOnCCA() {
   call HPLChipcon.cmd(CC2420_STXONCCA);
   return SUCCESS;
  }

  /*************************************************************************
   * RxMode
   * Shift the CC2420 Radio into receive mode 
   *************************************************************************/
  async command result_t CC2420Control.RxMode() {
    call HPLChipcon.cmd(CC2420_SRXON);
    return SUCCESS;
  }

  /*************************************************************************
   * SetRFPower
   * power = 31 => full power    (0dbm)
   *          3 => lowest power  (-25dbm)
   * return SUCCESS if the radio power was successfully set
   *************************************************************************/
  command result_t CC2420Control.SetRFPower(uint8_t power) {
    gCurrentParameters[CP_TXCTRL] = (gCurrentParameters[CP_FSCTRL] & 0xfff0) | (power << CC2420_TXCTRL_PAPWR);
    call HPLChipcon.write(CC2420_TXCTRL,gCurrentParameters[CP_TXCTRL]);
    return SUCCESS;
  }

  /*************************************************************************
   * GetRFPower
   * return power seeting
   *************************************************************************/
  command uint8_t CC2420Control.GetRFPower() {
    return (gCurrentParameters[CP_TXCTRL] & 0x000f); //rfpower;
  }

  async command result_t CC2420Control.OscillatorOn() {
    uint8_t i;
    uint8_t status;
    bool bXoscOn = FALSE;

    i = 0;
    call HPLChipcon.cmd(CC2420_SXOSCON);   //turn-on crystal
    while ((i < XOSC_TIMEOUT) && (bXoscOn == FALSE)) {
      TOSH_uwait(100);
      status = call HPLChipcon.cmd(CC2420_SNOP);      //read status
      status = status & ( 1 << CC2420_XOSC16M_STABLE);
      if (status) bXoscOn = TRUE;
      i++;
    }
    if (!bXoscOn) return FAIL;
    return SUCCESS;
  }

  async command result_t CC2420Control.OscillatorOff() {
    call HPLChipcon.cmd(CC2420_SXOSCOFF);   //turn-off crystal
    return SUCCESS;
  }

  async command result_t CC2420Control.VREFOn(){
    TOSH_SET_CC_VREN_PIN();                    //turn-on  
    TOSH_uwait(1800);          
  }

  async command result_t CC2420Control.VREFOff(){
    TOSH_CLR_CC_VREN_PIN();                    //turn-off  
    TOSH_uwait(1800);  
  }

  async command result_t CC2420Control.enableAutoAck() {
    gCurrentParameters[CP_MDMCTRL0] |= (1 << CC2420_MDMCTRL0_AUTOACK);
    return call HPLChipcon.write(CC2420_MDMCTRL0,gCurrentParameters[CP_MDMCTRL0]);
  }

  async command result_t CC2420Control.disableAutoAck() {
    gCurrentParameters[CP_MDMCTRL0] &= ~(1 << CC2420_MDMCTRL0_AUTOACK);
    return call HPLChipcon.write(CC2420_MDMCTRL0,gCurrentParameters[CP_MDMCTRL0]);
  }

  command result_t CC2420Control.setShortAddress(uint16_t addr) {
    addr = toLSB16(addr);
    return call HPLChipconRAM.write(CC2420_RAM_SHORTADR, 2, (uint8_t*)&addr);
  }

  async event result_t HPLChipcon.FIFOPIntr() {
    return SUCCESS;
  }

  async event result_t HPLChipconRAM.readDone(uint16_t addr, uint8_t length, uint8_t* buffer) {
     return SUCCESS;
  }

  async event result_t HPLChipconRAM.writeDone(uint16_t addr, uint8_t length, uint8_t* buffer) {
     return SUCCESS;
  }

  /**
  Enable CC2420 Receiver Hardware Address Decode.
  ************************************************************/
  async command result_t CC2420Control.enableAddrDecode() {
    gCurrentParameters[CP_MDMCTRL0] |= (CC2420_ADDRDECODE_ON << CC2420_MDMCTRL0_ADRDECODE);
    return call HPLChipcon.write(CC2420_MDMCTRL0,gCurrentParameters[CP_MDMCTRL0]);
  }
  /**
  Disable CC2420 Receiver Hardware Address Decode.
  ************************************************************/
  async command result_t CC2420Control.disableAddrDecode() {
    gCurrentParameters[CP_MDMCTRL0] &= ~(1 << CC2420_MDMCTRL0_ADRDECODE); //invert/clear
    return call HPLChipcon.write(CC2420_MDMCTRL0,gCurrentParameters[CP_MDMCTRL0]);
  }
	
}//CC2420ControlM module


