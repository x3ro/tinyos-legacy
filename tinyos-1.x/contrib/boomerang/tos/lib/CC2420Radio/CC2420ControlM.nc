// $Id: CC2420ControlM.nc,v 1.1.1.1 2007/11/05 19:11:23 jpolastre Exp $
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
 */

#include "byteorder.h"

/**
 * This module provides the CONTROL functionality for the 
 * Chipcon2420 series radio. It exports both a standard control 
 * interface and a custom interface to control CC2420 operation.
 *
 * @author Joe Polastre, Moteiv Corporation
 * @author Alan Broad, Crossbow
 */
module CC2420ControlM {
  provides {
    interface SplitControl;
    interface CC2420Control;
  }
  uses {
    interface StdControl as HPLChipconControl;
    interface HPLCC2420 as HPLChipcon;
    interface HPLCC2420RAM as HPLChipconRAM;
    interface HPLCC2420Interrupt as CCA;

    interface ResourceCmd as CmdCCAFired;
    interface ResourceCmd as CmdSplitControlInit;
    interface ResourceCmd as CmdSplitControlStart;
    interface ResourceCmd as CmdSplitControlStop;

    interface ResourceCmdAsync as CmdCmds;
  }
}
implementation
{

  enum {
    IDLE_STATE = 0,
    INIT_STATE,
    INIT_STATE_DONE,
    START_STATE,
    START_STATE_DONE,
    STOP_STATE,

    CMD_OSCILLATOR_ON = 1,
    CMD_OSCILLATOR_OFF = 2,

    CMD_SRXON = 1,
    CMD_STXON = 2,
    CMD_STXONCCA = 3,
  };

  typedef union {
    struct {
      uint8_t freqselect : 1;
      uint8_t setrfpower : 1;
      uint8_t setshortaddress : 1;
      uint8_t mdmctrl0 : 1;
      uint8_t oscillator : 2;
      uint8_t rxtxmode : 2;
    };
    uint8_t byte;
  } cmds_t;

  norace uint16_t gCurrentParameters[14];
  cmds_t cmds = { byte:0 };
  uint16_t shortAddress = 0;
  uint8_t state = 0;

  void doCmds( uint8_t rh );

   /************************************************************************
   * SetRegs
   *  - Configure CC2420 registers with current values
   *  - Readback 1st register written to make sure electrical connection OK
   *************************************************************************/
  bool SetRegs( uint8_t rh ) {
    uint16_t data;
	      
    call HPLChipcon.write(rh, CC2420_MAIN,gCurrentParameters[CP_MAIN]);   		    
    call HPLChipcon.write(rh, CC2420_MDMCTRL0, gCurrentParameters[CP_MDMCTRL0]);
    data = call HPLChipcon.read(rh, CC2420_MDMCTRL0);
    if (data != gCurrentParameters[CP_MDMCTRL0]) return FALSE;
    
    call HPLChipcon.write(rh, CC2420_MDMCTRL1, gCurrentParameters[CP_MDMCTRL1]);
    call HPLChipcon.write(rh, CC2420_RSSI, gCurrentParameters[CP_RSSI]);
    call HPLChipcon.write(rh, CC2420_SYNCWORD, gCurrentParameters[CP_SYNCWORD]);
    call HPLChipcon.write(rh, CC2420_TXCTRL, gCurrentParameters[CP_TXCTRL]);
    call HPLChipcon.write(rh, CC2420_RXCTRL0, gCurrentParameters[CP_RXCTRL0]);
    call HPLChipcon.write(rh, CC2420_RXCTRL1, gCurrentParameters[CP_RXCTRL1]);
    call HPLChipcon.write(rh, CC2420_FSCTRL, gCurrentParameters[CP_FSCTRL]);

    call HPLChipcon.write(rh, CC2420_SECCTRL0, gCurrentParameters[CP_SECCTRL0]);
    call HPLChipcon.write(rh, CC2420_SECCTRL1, gCurrentParameters[CP_SECCTRL1]);
    call HPLChipcon.write(rh, CC2420_IOCFG0, gCurrentParameters[CP_IOCFG0]);
    call HPLChipcon.write(rh, CC2420_IOCFG1, gCurrentParameters[CP_IOCFG1]);

    call HPLChipcon.cmd(rh, CC2420_SFLUSHTX);    //flush Tx fifo
    call HPLChipcon.cmd(rh, CC2420_SFLUSHRX);
 
    return TRUE;
  
  }


  /*************************************************************************
   * Init CC2420 radio:
   *
   *************************************************************************/

  event void CmdSplitControlInit.granted( uint8_t rh ) {

    call HPLChipconControl.init();
  
    // Set default parameters
    gCurrentParameters[CP_MAIN] = 0xf800;
    gCurrentParameters[CP_MDMCTRL0] = ((0 << CC2420_MDMCTRL0_ADRDECODE) | 
       (2 << CC2420_MDMCTRL0_CCAHIST) | (3 << CC2420_MDMCTRL0_CCAMODE)  | 
       (1 << CC2420_MDMCTRL0_AUTOCRC) | (2 << CC2420_MDMCTRL0_PREAMBL));

    gCurrentParameters[CP_MDMCTRL1] = 20 << CC2420_MDMCTRL1_CORRTHRESH;

    gCurrentParameters[CP_RSSI] =     0xE080;
    gCurrentParameters[CP_SYNCWORD] = 0xA70F;
    gCurrentParameters[CP_TXCTRL] = ((2 << CC2420_TXCTRL_BUFCUR) | 
       (1 << CC2420_TXCTRL_TURNARND) | (3 << CC2420_TXCTRL_PACUR) | 
       (1 << CC2420_TXCTRL_PADIFF) | (CC2420_RFPOWER << CC2420_TXCTRL_PAPWR));

    gCurrentParameters[CP_RXCTRL0] = ((1 << CC2420_RXCTRL0_BUFCUR) | 
       (2 << CC2420_RXCTRL0_MLNAG) | (3 << CC2420_RXCTRL0_LOLNAG) | 
       (2 << CC2420_RXCTRL0_HICUR) | (1 << CC2420_RXCTRL0_MCUR) | 
       (1 << CC2420_RXCTRL0_LOCUR));

    gCurrentParameters[CP_RXCTRL1] = ((1 << CC2420_RXCTRL1_RXBPF_LOCUR) |
       (1 << CC2420_RXCTRL1_LOW_LOWGAIN) | (1 << CC2420_RXCTRL1_HIGH_HGM) | 
       (1 << CC2420_RXCTRL1_LNA_CAP_ARRAY) | (1 << CC2420_RXCTRL1_RXMIX_TAIL) |
       (1 << CC2420_RXCTRL1_RXMIX_VCM) | (2 << CC2420_RXCTRL1_RXMIX_CURRENT));

    gCurrentParameters[CP_FSCTRL]   = ((1 << CC2420_FSCTRL_LOCK) | 
       ((357+5*(CC2420_CHANNEL-11)) << CC2420_FSCTRL_FREQ));

    gCurrentParameters[CP_SECCTRL0] = ((1 << CC2420_SECCTRL0_CBCHEAD) |
       (1 << CC2420_SECCTRL0_SAKEYSEL)  | (1 << CC2420_SECCTRL0_TXKEYSEL) | 
       (1 << CC2420_SECCTRL0_SECM));

    // set fifop threshold to greater than size of tos msg, 
    // fifop goes active at end of msg
    gCurrentParameters[CP_IOCFG0]   = (((127) << CC2420_IOCFG0_FIFOTHR) | 
        (1 <<CC2420_IOCFG0_FIFOPPOL)) ;

    atomic state = INIT_STATE_DONE;
    call CmdSplitControlInit.release();
    signal SplitControl.initDone();
  }


  command result_t SplitControl.init() {

    uint8_t _state = FALSE;

    atomic {
      if (state == IDLE_STATE) {
	state = INIT_STATE;
	_state = TRUE;
      }
    }
    if (!_state)
      return FAIL;

    call CmdSplitControlInit.deferRequest();
    return SUCCESS;
  }

  event void CmdSplitControlStop.granted( uint8_t rh ) {
    call HPLChipcon.cmd( rh, CC2420_SXOSCOFF ); 
    call CCA.disable();
    call HPLChipconControl.stop();

    TOSH_CLR_CC_RSTN_PIN();
    call CC2420Control.VREFOff();
    TOSH_SET_CC_RSTN_PIN();

    call CmdSplitControlStop.release();
    signal SplitControl.stopDone();
    atomic state = INIT_STATE_DONE;
  }

  command result_t SplitControl.stop() {
    uint8_t _state = FALSE;

    atomic {
      if (state == START_STATE_DONE) {
	state = STOP_STATE;
	_state = TRUE;
      }
    }
    if (!_state)
      return FAIL;

    call CmdSplitControlStop.deferRequest();
    return SUCCESS;
  }

/******************************************************************************
 * Start CC2420 radio:
 * -Turn on 1.8V voltage regulator, wait for power-up, 0.6msec
 * -Release reset line
 * -Enable CC2420 crystal,          wait for stabilization, 0.9 msec
 *
 ******************************************************************************/

  event void CmdSplitControlStart.granted( uint8_t rh ) {
    call HPLChipconControl.start();
    //turn on power
    call CC2420Control.VREFOn();
    // toggle reset
    TOSH_CLR_CC_RSTN_PIN();
    TOSH_wait();
    TOSH_SET_CC_RSTN_PIN();
    TOSH_wait();
    // turn on crystal, takes about 860 usec, 
    // chk CC2420 status reg for stablize
    call CC2420Control.OscillatorOn( rh );
    call CmdSplitControlStart.release();
  }

  command result_t SplitControl.start() {
    uint8_t _state = FALSE;

    atomic {
      if (state == INIT_STATE_DONE) {
	state = START_STATE;
	_state = TRUE;
      }
    }
    if (!_state)
      return FAIL;

    call CmdSplitControlStart.deferRequest();
    return SUCCESS;
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
  void doCmdFreqSelect( uint8_t rh ) {
    uint8_t status = call HPLChipcon.write( rh, CC2420_FSCTRL, gCurrentParameters[CP_FSCTRL] );
    // if the oscillator is started, recalibrate for the new frequency
    // if the oscillator is NOT on, we should not transition to RX mode
    if (status & (1 << CC2420_XOSC16M_STABLE))
      call HPLChipcon.cmd( rh, CC2420_SRXON );
  }

  command result_t CC2420Control.TunePreset( uint8_t rh, uint8_t chnl ) {
    int fsctrl = 357 + 5*(chnl-11);
    gCurrentParameters[CP_FSCTRL] = (gCurrentParameters[CP_FSCTRL] & 0xfc00) | (fsctrl << CC2420_FSCTRL_FREQ);
    atomic cmds.freqselect = 1;
    doCmds(rh);
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
  command result_t CC2420Control.TuneManual( uint8_t rh, uint16_t DesiredFreq) {
    int fsctrl;
   
    fsctrl = DesiredFreq - 2048;
    gCurrentParameters[CP_FSCTRL] = (gCurrentParameters[CP_FSCTRL] & 0xfc00) | (fsctrl << CC2420_FSCTRL_FREQ);
    atomic cmds.freqselect = 1;
    doCmds(rh);
    return SUCCESS;
  }


  /*************************************************************************
   * Get the current frequency of the radio
   */
  command uint16_t CC2420Control.GetFrequency() {
    return ((gCurrentParameters[CP_FSCTRL] & (0x1FF << CC2420_FSCTRL_FREQ))+2048);
  }

  /*************************************************************************
   * Get the current channel of the radio
   */
  command uint8_t CC2420Control.GetPreset() {
    uint16_t _freq = (gCurrentParameters[CP_FSCTRL] & (0x1FF << CC2420_FSCTRL_FREQ));
    _freq = (_freq - 357)/5;
    _freq = _freq + 11;
    return _freq;
  }

  /*************************************************************************
   * TxMode
   * Shift the CC2420 Radio into transmit mode.
   * return SUCCESS if the radio was successfully switched to TX mode.
   *************************************************************************/
  void doCmdSTXON( uint8_t rh ) {
    call HPLChipcon.cmd( rh, CC2420_STXON );
  }

  async command result_t CC2420Control.TxMode( uint8_t rh ) {
    atomic cmds.rxtxmode = CMD_STXON;
    doCmds(rh);
    return SUCCESS;
  }

  /*************************************************************************
   * TxModeOnCCA
   * Shift the CC2420 Radio into transmit mode when the next clear channel
   * is detected.
   *
   * return SUCCESS if the transmit request has been accepted
   *************************************************************************/
  void doCmdSTXONCCA( uint8_t rh ) {
    call HPLChipcon.cmd( rh, CC2420_STXONCCA );
  }

  async command result_t CC2420Control.TxModeOnCCA( uint8_t rh ) {
    atomic cmds.rxtxmode = CMD_STXONCCA;
    doCmds(rh);
    return SUCCESS;
  }

  /*************************************************************************
   * RxMode
   * Shift the CC2420 Radio into receive mode 
   *************************************************************************/
  void doCmdSRXON( uint8_t rh ) {
    call HPLChipcon.cmd( rh, CC2420_SRXON );
  }

  async command result_t CC2420Control.RxMode( uint8_t rh ) {
    atomic cmds.rxtxmode = CMD_SRXON;
    doCmds(rh);
    return SUCCESS;
  }

  /*************************************************************************
   * SetRFPower
   * power = 31 => full power    (0dbm)
   *          3 => lowest power  (-25dbm)
   * return SUCCESS if the radio power was successfully set
   *************************************************************************/
  void doCmdSetRFPower( uint8_t rh ) {
    call HPLChipcon.write( rh, CC2420_TXCTRL, gCurrentParameters[CP_TXCTRL] );
  }

  command result_t CC2420Control.SetRFPower( uint8_t rh, uint8_t power ) {
    gCurrentParameters[CP_TXCTRL] = (gCurrentParameters[CP_TXCTRL] & (~CC2420_TXCTRL_PAPWR_MASK)) | (power << CC2420_TXCTRL_PAPWR);
    atomic cmds.setrfpower=1;
    doCmds(rh);
    return SUCCESS;
  }

  /*************************************************************************
   * GetRFPower
   * return power seeting
   *************************************************************************/
  command uint8_t CC2420Control.GetRFPower() {
    return (gCurrentParameters[CP_TXCTRL] & CC2420_TXCTRL_PAPWR_MASK); //rfpower;
  }

  void doCmdOscillatorOn( uint8_t rh ) {
    // uncomment to measure the startup time from 
    // high to low to high transitions
    // output "1" on the CCA pin
#ifdef CC2420_MEASURE_OSCILLATOR_STARTUP
      call HPLChipcon.write( rh, CC2420_IOCFG1, 31 );
      // output oscillator stable on CCA pin
      // error in CC2420 datasheet 1.2: SFDMUX and CCAMUX incorrectly labelled
      TOSH_uwait(50);
#endif

    call HPLChipcon.write( rh, CC2420_IOCFG1, 24 );

    // have an event/interrupt triggered when it starts up
    call CCA.startWait( TRUE );
    
    // start the oscillator
    call HPLChipcon.cmd( rh, CC2420_SXOSCON );   //turn-on crystal
  }


  async command result_t CC2420Control.OscillatorOn( uint8_t rh ) {
    atomic cmds.oscillator = CMD_OSCILLATOR_ON;
    doCmds(rh);
    return SUCCESS;
  }

  void doCmdOscillatorOff( uint8_t rh ) {
    call HPLChipcon.cmd(rh, CC2420_SXOSCOFF);   //turn-off crystal
  }

  async command result_t CC2420Control.OscillatorOff( uint8_t rh ) {
    atomic cmds.oscillator = CMD_OSCILLATOR_OFF;
    doCmds(rh);
    return SUCCESS;
  }

  async command result_t CC2420Control.VREFOn(){
    TOSH_SET_CC_VREN_PIN();                    //turn-on  
    // TODO: JP: measure the actual time for VREF to stabilize
    TOSH_uwait(600);  // CC2420 spec: 600us max turn on time
    return SUCCESS;
  }

  async command result_t CC2420Control.VREFOff(){
    TOSH_CLR_CC_VREN_PIN();                    //turn-off  
    return SUCCESS;
  }

  void doCmdMDMCTRL0( uint8_t rh ) {
    call HPLChipcon.write( rh, CC2420_MDMCTRL0, gCurrentParameters[CP_MDMCTRL0] );
  }

  async command result_t CC2420Control.enableAutoAck( uint8_t rh ) {
    gCurrentParameters[CP_MDMCTRL0] |= (1 << CC2420_MDMCTRL0_AUTOACK);
    atomic cmds.mdmctrl0 = 1;
    doCmds(rh);
    return SUCCESS;
  }

  async command result_t CC2420Control.disableAutoAck( uint8_t rh ) {
    gCurrentParameters[CP_MDMCTRL0] &= ~(1 << CC2420_MDMCTRL0_AUTOACK);
    atomic cmds.mdmctrl0 = 1;
    doCmds(rh);
    return SUCCESS;
  }

  async command result_t CC2420Control.enableAddrDecode( uint8_t rh ) {
    gCurrentParameters[CP_MDMCTRL0] |= (1 << CC2420_MDMCTRL0_ADRDECODE);
    atomic cmds.mdmctrl0 = 1;
    doCmds(rh);
    return SUCCESS;
  }

  async command result_t CC2420Control.disableAddrDecode( uint8_t rh ) {
    gCurrentParameters[CP_MDMCTRL0] &= ~(1 << CC2420_MDMCTRL0_ADRDECODE);
    atomic cmds.mdmctrl0 = 1;
    doCmds(rh);
    return SUCCESS;
  }

  void doCmdSetShortAddress( uint8_t rh ) {
    call HPLChipconRAM.write( rh, CC2420_RAM_SHORTADR, 2, (uint8_t*)&shortAddress );
  }

  command result_t CC2420Control.setShortAddress( uint8_t rh, uint16_t addr ) {
    shortAddress = toLSB16(addr);
    atomic cmds.setshortaddress = 1;
    doCmds(rh);
    return SUCCESS;
  }

  async event result_t HPLChipconRAM.readDone(uint16_t addr, uint8_t length, uint8_t* buffer) {
    return SUCCESS;
  }

  async event result_t HPLChipconRAM.writeDone(uint16_t addr, uint8_t length, uint8_t* buffer) {
    return SUCCESS;
  }

  event void CmdCCAFired.granted( uint8_t rh ) {
    // reset the CCA pin back to the CCA function
    call HPLChipcon.write(rh, CC2420_IOCFG1, 0);
    //set freq, load regs
    SetRegs(rh);
    call CC2420Control.setShortAddress( rh, TOS_LOCAL_ADDRESS );
    call CC2420Control.TuneManual( rh, ((gCurrentParameters[CP_FSCTRL] << CC2420_FSCTRL_FREQ) & 0x1FF) + 2048 );

    atomic state = START_STATE_DONE;
    call CmdCCAFired.release();
    signal SplitControl.startDone();
  }

  async event result_t CCA.fired() {
    call CmdCCAFired.deferRequest();
    return FAIL;
  }

  async event void CmdCmds.granted( uint8_t rh ) {
    cmds_t c;
    atomic {
      c = cmds;
      cmds.byte = 0;
    }
    if( c.freqselect ) { doCmdFreqSelect(rh); }
    if( c.setrfpower ) { doCmdSetRFPower(rh); }
    if( c.setshortaddress ) { doCmdSetShortAddress(rh); }
    if( c.mdmctrl0 ) { doCmdMDMCTRL0(rh); }
    switch( c.oscillator ) {
      case CMD_OSCILLATOR_ON: doCmdOscillatorOn(rh); break;
      case CMD_OSCILLATOR_OFF: doCmdOscillatorOff(rh); break;
    }
    switch( c.rxtxmode ) {
      case CMD_SRXON: doCmdSRXON(rh); break;
      case CMD_STXON: doCmdSTXON(rh); break;
      case CMD_STXONCCA: doCmdSTXONCCA(rh); break;
    }
    call CmdCmds.release();
  }

  void doCmds( uint8_t rh ) {
    call CmdCmds.request( rh );
  }
}

