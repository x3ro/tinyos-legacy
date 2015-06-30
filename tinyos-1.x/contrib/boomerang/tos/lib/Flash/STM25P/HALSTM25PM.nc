// $Id: HALSTM25PM.nc,v 1.1.1.1 2007/11/05 19:11:27 jpolastre Exp $

/*									tab:4
 * "Copyright (c) 2000-2005 The Regents of the University  of California.  
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

/*
 * @author: Jonathan Hui <jwhui@cs.berkeley.edu>
 */

module HALSTM25PM {
  provides {
    interface StdControl;
    interface HALSTM25P[volume_t volume];
  }
  uses {
    interface HPLSTM25P;
    interface Leds;
    interface Timer;
    interface ResourceCmd as CmdRequest;
    interface ResourceCmd as CmdWriteSR;
    interface ResourceCmd as CmdTimer;
    interface ResourceValidate;
  }
}

implementation {

  enum {
    S_POWEROFF = 0xfe,  // deep power-down state
    S_POWERON  = 0xff,  // awake state, no command in progress
  };

  typedef struct {
    stm25p_addr_t len;
    stm25p_addr_t addr;
    uint8_t* data;
    volume_t volume;
    uint8_t cmd;
  } Request_t;

  typedef struct {
    volume_t volume;
    uint8_t value;
  } WriteSR_t;

  volume_t curVolume;
  stm25p_sig_t signature;
  uint16_t crcScratch;
  uint8_t curCmd;

  Request_t m_request;
  bool m_requesting;

  WriteSR_t m_writesr;
  bool m_is_writesr;

  

  void sendCmd(uint8_t rh, uint8_t cmd, stm25p_addr_t addr, void* data, stm25p_addr_t len);

  command result_t StdControl.init() {
    curCmd = S_POWEROFF;
    signature = STM25P_INVALID_SIG;
    m_requesting = FALSE;
    m_is_writesr = FALSE;
    return SUCCESS;
  }

  command result_t StdControl.start() { return SUCCESS; }
  command result_t StdControl.stop() { return SUCCESS; }

  void signalDone() {

    uint8_t tmpCmd = curCmd;
    curCmd = S_POWERON;

    call Timer.start(TIMER_ONE_SHOT, STM25P_POWEROFF_DELAY);

    switch(tmpCmd) {
    case STM25P_PP: signal HALSTM25P.pageProgramDone[curVolume](); break;
    case STM25P_SE: signal HALSTM25P.sectorEraseDone[curVolume](); break;
    case STM25P_BE: signal HALSTM25P.bulkEraseDone[curVolume](); break;
    case STM25P_WRSR: signal HALSTM25P.writeSRDone[curVolume](); break;
    }

  }

  bool isWriting( uint8_t rh ) {
    uint8_t status;
    sendCmd(rh, STM25P_RDSR, 0, &status, sizeof(status));
    return !!(status & 0x1);
  }

  void powerOff( uint8_t rh ) {
    sendCmd(rh, STM25P_DP, 0, NULL, 0);
    curCmd = S_POWEROFF;
  }

  void powerOn( uint8_t rh ) {
    sendCmd(rh, STM25P_RES, 0, &signature, sizeof(signature));
    TOSH_uwait(2); // wait at least 1.8us to power on
    curCmd = S_POWERON;
  }

  event result_t Timer.fired() {

    call CmdTimer.deferRequest();
    return SUCCESS;

  }

  event void CmdTimer.granted( uint8_t rh ) {

    if (curCmd == S_POWERON) {
      powerOff(rh);
      call CmdTimer.release();
    }
    else {
      bool writing = isWriting( rh );
      call CmdTimer.release();
      if( writing )
        call Timer.start(TIMER_ONE_SHOT, 1);
      else
        signalDone();
    }

  }

  void sendCmd(uint8_t rh, uint8_t cmd, stm25p_addr_t addr, void* data, stm25p_addr_t len) {

    uint8_t cmdBytes[2*STM25P_ADDR_SIZE + 1];
    uint8_t i;

    // begin command
    call HPLSTM25P.beginCmd( rh );
    
    cmdBytes[0] = STM25P_CMDS[cmd].cmd;

    // command, address and dummy bytes
    for ( i = 0; i < STM25P_ADDR_SIZE; i++ )
      cmdBytes[i+1] = (addr >> ((STM25P_ADDR_SIZE-1-i)*8)) & 0xff;
    call HPLSTM25P.txBuf(rh, cmdBytes, (STM25P_CMD_SIZE +
				    STM25P_CMDS[cmd].address +
				    STM25P_CMDS[cmd].dummy) );

    // data
    if (STM25P_CMDS[cmd].receive) {
      crcScratch = call HPLSTM25P.rxBuf(rh, data, len, crcScratch);
      //leds_red_toggle(); //toggles on tmote
    }
    else if (STM25P_CMDS[cmd].transmit)
      call HPLSTM25P.txBuf(rh, data, len);

    // end command
    call HPLSTM25P.endCmd( rh );

  }

  result_t newRequest(uint8_t cmd, volume_t volume, stm25p_addr_t addr, uint8_t* data, stm25p_addr_t len) {

    if (curCmd != S_POWERON && curCmd != S_POWEROFF) {
      //leds_set(2); // never goes off on tmote when Deluge is stuck on page 1
      return FAIL;
    }

    if( m_requesting == FALSE ) {
      call Timer.stop();
      m_requesting = TRUE;
      m_request.cmd = cmd;
      m_request.volume = volume;
      m_request.addr = addr;
      m_request.data = data;
      m_request.len = len;
      call CmdRequest.deferRequest();
      return SUCCESS;
    }

    //leds_set(3); // never goes off on tmote when Deluge is stuck on page 1
    return FAIL;
  }

  result_t immediateRequest(uint8_t rh, uint8_t cmd, volume_t volume, stm25p_addr_t addr, uint8_t* data, stm25p_addr_t len) {
    if( call ResourceValidate.validateUser(rh) ) {
      if (curCmd == S_POWEROFF)
        powerOn( rh );

      curVolume = volume;
      curCmd = cmd;

      // enable writes
      if (STM25P_CMDS[curCmd].write)
        sendCmd(rh, STM25P_WREN, 0, NULL, 0);

      // send command
      sendCmd(rh, curCmd, addr, data, len);

      // post check for write done
      if (STM25P_CMDS[curCmd].write)
        call Timer.start(TIMER_ONE_SHOT, 1);
      else {
        curCmd = S_POWERON;
        call Timer.start(TIMER_ONE_SHOT, STM25P_POWEROFF_DELAY);
      }
      return SUCCESS;
    }
    //leds_set(3); // never goes off on tmote when Deluge is stuck on page 1
    return FAIL;
  }

  event void CmdRequest.granted( uint8_t rh ) {
    immediateRequest( rh, m_request.cmd, m_request.volume, m_request.addr, m_request.data, m_request.len );
    m_requesting = FALSE;
    call CmdRequest.release();
  }

  command result_t HALSTM25P.read[volume_t volume](uint8_t rh, stm25p_addr_t addr, void* data, stm25p_addr_t len) {
    return immediateRequest(rh, STM25P_READ, volume, addr, data, len);
  }

  command result_t HALSTM25P.pageProgram[volume_t volume](stm25p_addr_t addr, void* data, stm25p_addr_t len) {
    return newRequest(STM25P_PP, volume, addr, data, len);
  }

  command result_t HALSTM25P.sectorErase[volume_t volume](stm25p_addr_t addr) {
    return newRequest(STM25P_SE, volume, addr, NULL, 0);
  }

  command result_t HALSTM25P.bulkErase[volume_t volume]() {
    return newRequest(STM25P_BE, volume, 0, NULL, 0);
  }

  command result_t HALSTM25P.readSR[volume_t volume](uint8_t rh, void* value) {
    return immediateRequest(rh, STM25P_RDSR, volume, 0, value, 1);
  }

  command result_t HALSTM25P.writeSR[volume_t volume](uint8_t value) {

    // 15 dec 2005 css: Deluge and STM25P fail unless writeSR can enqueue in
    // parallel with the other commands.  So, give writeSR its own resource.

    if( m_is_writesr == FALSE ) {
      m_is_writesr = TRUE;
      m_writesr.volume = volume;
      m_writesr.value = value;
      call CmdWriteSR.deferRequest();
      return SUCCESS;
    }
    return FAIL;
  }

  event void CmdWriteSR.granted( uint8_t rh ) {
    immediateRequest(rh, STM25P_WRSR, m_writesr.volume, 0, &m_writesr.value, 1);
    m_is_writesr = FALSE;
    call CmdWriteSR.release();
  }

  command result_t HALSTM25P.computeCrc[volume_t volume](uint8_t rh, uint16_t* crcResult, uint16_t crc, stm25p_addr_t addr, stm25p_addr_t len) {
    result_t result;
    crcScratch = crc;
    result = immediateRequest(rh, STM25P_CRC, volume, addr, NULL, len);
    *crcResult = crcScratch;
    return result;
  }

  command stm25p_sig_t HALSTM25P.getSignature[volume_t volume]() { 
    return signature; 
  }
  
  default event void HALSTM25P.pageProgramDone[volume_t volume]() {}
  default event void HALSTM25P.sectorEraseDone[volume_t volume]() {}
  default event void HALSTM25P.bulkEraseDone[volume_t volume]() {}
  default event void HALSTM25P.writeSRDone[volume_t volume]() {}

}
