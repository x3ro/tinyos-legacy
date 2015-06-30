// $Id: CC2420RadioM.nc,v 1.1 2004/12/11 16:49:26 kusyb Exp $

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
 *  Authors: Joe Polastre
 *  Date last modified: $Revision: 1.1 $
 *
 * This module provides the layer2 functionality for the mica2 radio.
 * While the internal architecture of this module is not CC2420 specific,
 * It does make some CC2420 specific calls via CC2420Control.
 * 
 * $Id: CC2420RadioM.nc,v 1.1 2004/12/11 16:49:26 kusyb Exp $
 */

/**
 * @author Joe Polastre
 * @author Alan Broad, Crossbow
 */

includes byteorder;

module CC2420RadioM {
  provides {
    interface StdControl;
    interface BareSendMsg as Send;
    interface ReceiveMsg as Receive;
    interface RadioCoordinator as RadioSendCoordinator;
    interface RadioCoordinator as RadioReceiveCoordinator;
    interface MacControl;
    interface MacBackoff;
  }
  uses {
    interface StdControl as CC2420StdControl;
    interface CC2420Control;
    interface HPLCC2420 as HPLChipcon;
    interface HPLCC2420FIFO as HPLChipconFIFO; 
    interface StdControl as TimerControl;
    interface TimerJiffyAsync as BackoffTimerJiffy;
    interface Random;
    interface Leds;
  }
}

implementation {
  enum {
    DISABLED_STATE = 0,
    IDLE_STATE,
    TX_STATE,
    PRE_TX_STATE,
    POST_TX_STATE,
    POST_TX_ACK_STATE,
    RX_STATE,
    POWER_DOWN_STATE,

    TIMER_INITIAL = 0,
    TIMER_BACKOFF,
    TIMER_ACK
  };

#define MAX_SEND_TRIES 8

  norace uint8_t countRetry;
  uint8_t stateRadio;
  norace uint8_t stateTimer;
  norace uint8_t currentDSN;
  norace bool bAckEnable;
  uint16_t txlength;
  uint16_t rxlength;
  norace TOS_MsgPtr txbufptr;  // pointer to transmit buffer
  norace TOS_MsgPtr rxbufptr;  // pointer to receive buffer
  TOS_Msg RxBuf;	// save received messages

  // XXX-PB:
  // Here's the deal, the mica (RFM) radio stacks used TOS_LOCAL_ADDRESS
  // to determine if an L2 ack was reqd.  This stack doesn't do L2 acks
  // and, thus doesn't need it.  HOWEVER, some set-mote-id versions
  // break if this symbol is missing from the binary.
  // Thus, I put this LocalAddr here and set it to TOS_LOCAL_ADDRESS
  // to keep things happy for now.
  volatile uint16_t LocalAddr;

  ///**********************************************************
  //* local function definitions
  //**********************************************************/

   void sendFailed() {
     atomic stateRadio = IDLE_STATE;
     txbufptr->length = txbufptr->length - MSG_HEADER_SIZE - MSG_FOOTER_SIZE;
     signal Send.sendDone(txbufptr, FAIL);
   }

   inline result_t setInitialTimer( uint16_t jiffy ) {
     stateTimer = TIMER_INITIAL;
     return call BackoffTimerJiffy.setOneShot(jiffy);
   }

   inline result_t setBackoffTimer( uint16_t jiffy ) {
     stateTimer = TIMER_BACKOFF;
     return call BackoffTimerJiffy.setOneShot(jiffy);
   }

   inline result_t setAckTimer( uint16_t jiffy ) {
     stateTimer = TIMER_ACK;
     return call BackoffTimerJiffy.setOneShot(jiffy);
   }

/******************************************************************************
 * PacketRcvd
 * - Radio packet rcvd, signal 
 *****************************************************************************/
   task void PacketRcvd() {
    TOS_MsgPtr pBuf;

    atomic {
      rxbufptr->time = 0;
      pBuf = rxbufptr;
    }
    pBuf = signal Receive.receive((TOS_MsgPtr)pBuf);
    atomic {
      if (pBuf) rxbufptr = pBuf;
      rxbufptr->length = 0;
    }
  }

  
  task void PacketSent() {
    TOS_MsgPtr pBuf; //store buf on stack 

    atomic {
      stateRadio = IDLE_STATE;
      txbufptr->time = 0;
      pBuf = txbufptr;
      pBuf->length = pBuf->length - MSG_HEADER_SIZE - MSG_FOOTER_SIZE;
    }

    signal Send.sendDone(pBuf,SUCCESS);
  }

  ///**********************************************************
  //* Exported interface functions
  //**********************************************************/
  
  command result_t StdControl.init() {

    atomic {
      stateRadio = DISABLED_STATE;
      currentDSN = 0;
      bAckEnable = FALSE;
      rxbufptr = &RxBuf;
      rxbufptr->length = 0;
      rxlength = MSG_DATA_SIZE-2;
    }

    call CC2420StdControl.init();
    call TimerControl.init();
    call Random.init();
    LocalAddr = TOS_LOCAL_ADDRESS;

    return SUCCESS;
  }
  
  command result_t StdControl.stop() {
    atomic stateRadio = DISABLED_STATE;

    call TimerControl.stop();
    call CC2420StdControl.stop();
    return SUCCESS;
  }

  command result_t StdControl.start() {
    uint8_t chkstateRadio;

    atomic chkstateRadio = stateRadio;

    if (chkstateRadio == DISABLED_STATE) {
      atomic {
        countRetry = 0;
        rxbufptr->length = 0;
        
	call TimerControl.start();
        call CC2420StdControl.start();  // PRESENT STRATEGY WILL WAIT ~2 msec
        call CC2420Control.RxMode();
        call HPLChipcon.enableFIFOP();  //enable interrupt when pkt rcvd

        stateRadio  = IDLE_STATE;
      }
    }
    return SUCCESS;
  }

  void sendPacket() {
    uint8_t status;

//signal Foo.tx0();  
    call HPLChipcon.cmd(CC2420_STXONCCA);
    status = call HPLChipcon.cmd(CC2420_SNOP);
    if ((status >> CC2420_TX_ACTIVE) & 0x01) {
//      TOSH_uwait(450);           // ~ 400 usec delay until SFD goes high!!!
      while (!TOSH_READ_CC_SFD_PIN()){};
//      signal Foo.tx1();  
      signal RadioSendCoordinator.startSymbol(8,0,txbufptr); 
      
      while (TOSH_READ_CC_SFD_PIN()){};  // wait until SFD pin goes low
//signal Foo.tx2();
      atomic stateRadio = POST_TX_STATE;
      if (bAckEnable) {
        if (!(setAckTimer(CC2420_ACK_DELAY)))
          sendFailed();
      }
      else {
        if (!post PacketSent())
          sendFailed();
      }
    }
    else {
      atomic stateRadio = PRE_TX_STATE;
      if (!(setBackoffTimer(signal MacBackoff.congestionBackoff(txbufptr) * CC2420_SYMBOL_UNIT))) {
        sendFailed();
      }
    }
  }

  task void startSend() {
    if (!(call HPLChipcon.cmd(CC2420_SFLUSHTX))) {
      sendFailed();
      return;
    }
    if (!(call HPLChipconFIFO.writeTXFIFO(txlength+1,(uint8_t*)txbufptr))) {
      sendFailed();
      return;
    }
  }

  void tryToSend() {
     uint8_t currentstate;
     atomic currentstate = stateRadio;

     // and the CCA check is good
     if (currentstate == PRE_TX_STATE) {
       if (TOSH_READ_RADIO_CCA_PIN()) {
         atomic stateRadio = TX_STATE;
         sendPacket();
       }
       else {
         if (countRetry-- <= 0) {
           call HPLChipcon.read(CC2420_RXFIFO);          //flush Rx fifo
           call HPLChipcon.cmd(CC2420_SFLUSHRX);
           call HPLChipcon.read(CC2420_RXFIFO);          //flush Rx fifo
           call HPLChipcon.cmd(CC2420_SFLUSHRX);
           sendFailed();
           return;
         }
         if (!(setBackoffTimer(signal MacBackoff.congestionBackoff(txbufptr) * CC2420_SYMBOL_UNIT))) {
           sendFailed();
         }
       }
     }
  }

  async event result_t BackoffTimerJiffy.fired() {
    uint8_t currentstate;
    atomic currentstate = stateRadio;

    switch (stateTimer) {
    case TIMER_INITIAL:
      if (!(post startSend())) {
        sendFailed();
      }
      break;
    case TIMER_BACKOFF:
      tryToSend();
      break;
    case TIMER_ACK:
      if (currentstate == POST_TX_STATE) {
        txbufptr->ack = 0;
        post PacketSent();
      }
      break;
    }
    return SUCCESS;
  }

 /**********************************************************
   * Send
   * - Xmit a packet
   *    USE SFD FALLING FOR END OF XMIT !!!!!!!!!!!!!!!!!! interrupt???
   * - If in power-down state start timer ? !!!!!!!!!!!!!!!!!!!!!!!!!s
   * - If !TxBusy then 
   *   a) Flush the tx fifo 
   *   b) Write Txfifo address
   *    
   **********************************************************/
  command result_t Send.send(TOS_MsgPtr pMsg) {

    uint8_t currentstate;
    atomic currentstate = stateRadio;

    if (currentstate == IDLE_STATE) {
      // put default FCF values in to get address checking to pass
      pMsg->fcflo = CC2420_DEF_FCF_LO;
      if (bAckEnable) 
        pMsg->fcfhi = CC2420_DEF_FCF_HI_ACK;
      else 
        pMsg->fcfhi = CC2420_DEF_FCF_HI;
      // destination PAN is broadcast
      pMsg->destpan = TOS_BCAST_ADDR;
      // adjust the destination address to be in the right byte order
      pMsg->addr = toLSB16(pMsg->addr);
      // adjust the data length to now include the full packet length
      pMsg->length = pMsg->length + MSG_HEADER_SIZE + MSG_FOOTER_SIZE;
      // keep the DSN increasing for ACK recognition
      pMsg->dsn = ++currentDSN;
      // FCS bytes generated by CC2420
      txlength = pMsg->length - MSG_FOOTER_SIZE;  
      txbufptr = pMsg;
      countRetry = MAX_SEND_TRIES;
      if (setInitialTimer(signal MacBackoff.initialBackoff(txbufptr) * CC2420_SYMBOL_UNIT)) {
        atomic stateRadio = PRE_TX_STATE;
        return SUCCESS;
      }
    }
    return FAIL;

  }
  
  task void delayedRXFIFO() {
     uint8_t len = MSG_DATA_SIZE;
     call HPLChipconFIFO.readRXFIFO(len,(uint8_t*)rxbufptr);
  }    

  /**********************************************************
   * FIFOP lo Interrupt: Rx data avail in CC2420 fifo
   * Radio must have been in Rx mode to get this interrupt
   * If FIFO pin =lo then fifo overflow=> flush fifo & exit
   * 
   *
   * Things ToDo:
   *
   * -Disable FIFOP interrupt until PacketRcvd task complete 
   * until send.done complete
   *
   * -Fix mixup: on return
   *  rxbufptr->rssi is CRC + Correlation value
   *  rxbufptr->strength is RSSI
   **********************************************************/
   async event result_t HPLChipcon.FIFOPIntr() {
     //signal Foo.rcv();
     signal RadioReceiveCoordinator.startSymbol(8,0,rxbufptr); 
     // if we're trying to send a message and a FIFOP interrupt occurs
     // and acks are enabled, we need to backoff longer so that we don't
     // interfere with the ACK
     if (bAckEnable && (stateRadio == PRE_TX_STATE)) {
       if (call BackoffTimerJiffy.isSet()) {
         call BackoffTimerJiffy.stop();
         call BackoffTimerJiffy.setOneShot((signal MacBackoff.congestionBackoff(txbufptr) * CC2420_SYMBOL_UNIT) + CC2420_ACK_DELAY);
       }
     }

     /** THIS SHOULD NEVER HAPPEN-- FIFOP will only be set
      *  if the FIFO contains data -and- is valid     */
     if (!TOSH_READ_CC_FIFO_PIN()){
         call HPLChipcon.read(CC2420_RXFIFO);          //flush Rx fifo
         call HPLChipcon.cmd(CC2420_SFLUSHRX);
       return SUCCESS;
     }
     
     post delayedRXFIFO();

     return SUCCESS;
  }

  async event result_t HPLChipconFIFO.RXFIFODone(uint8_t length, uint8_t *data) {
    uint8_t currentstate;
    atomic currentstate = stateRadio;
    // if there's still data in the fifo, must be corrupt, flush it
    if (TOSH_READ_CC_FIFO_PIN()) {
      call HPLChipcon.read(CC2420_RXFIFO);          //flush Rx fifo
      call HPLChipcon.cmd(CC2420_SFLUSHRX);
    }

    // is the packet larger than we can handle?
    if (length > MSG_DATA_SIZE)
      return SUCCESS;

    rxbufptr = (TOS_MsgPtr)data;

    if (bAckEnable && (currentstate == POST_TX_STATE) &&
         ((rxbufptr->fcfhi & 0x03) == CC2420_DEF_FCF_TYPE_ACK) &&
         (rxbufptr->dsn == currentDSN)) {
      atomic {
        txbufptr->ack = 1;
        txbufptr->strength = data[length-2];
        txbufptr->lqi = data[length-1] & 0x7F;
        currentstate = POST_TX_ACK_STATE;
      }
      post PacketSent();
    }

    if ((rxbufptr->fcfhi & 0x03) != CC2420_DEF_FCF_TYPE_DATA)
      return SUCCESS;

    rxbufptr->length = rxbufptr->length - MSG_HEADER_SIZE - MSG_FOOTER_SIZE;
    // adjust destination to the right byte order
    rxbufptr->addr = fromLSB16(rxbufptr->addr);
 
    // if the length is shorter, we have to move the CRC bytes
    rxbufptr->crc = data[length-1] >> 7;
    // put in RSSI
    rxbufptr->strength = data[length-2];
    // put in LQI
    rxbufptr->lqi = data[length-1] & 0x7F;

    post PacketRcvd();	

    return SUCCESS;     
  }

  async event result_t HPLChipconFIFO.TXFIFODone(uint8_t length, uint8_t *data) { 
     tryToSend();
     return SUCCESS;
  }

  async command void MacControl.enableAck() {
    atomic bAckEnable = TRUE;
    call CC2420Control.enableAddrDecode();
    call CC2420Control.enableAutoAck();
  }

  async command void MacControl.disableAck() {
    atomic bAckEnable = FALSE;
    call CC2420Control.disableAddrDecode();
    call CC2420Control.disableAutoAck();
  }

  /**
   * How many basic time periods to back off.
   * Each basic time period consists of 20 symbols (16uS per symbol)
   */
  default async event int16_t MacBackoff.initialBackoff(TOS_MsgPtr m) {
    return (call Random.rand() & 0xF) + 1;
  }
  /**
   * How many symbols to back off when there is congestion (16uS per symbol)
   */
  default async event int16_t MacBackoff.congestionBackoff(TOS_MsgPtr m) {
    return (call Random.rand() & 0xF) + 1;
  }

// Default events for radio send/receive coordinators do nothing.
// Be very careful using these, you'll break the stack.
default async event void RadioSendCoordinator.startSymbol(uint8_t bitsPerBlock, uint8_t offset, TOS_MsgPtr msgBuff) { }
default async event void RadioSendCoordinator.byte(TOS_MsgPtr msg, uint8_t byteCount) { }
default async event void RadioReceiveCoordinator.startSymbol(uint8_t bitsPerBlock, uint8_t offset, TOS_MsgPtr msgBuff) { }
default async event void RadioReceiveCoordinator.byte(TOS_MsgPtr msg, uint8_t byteCount) { }
//default	async event void Foo.tx0(){}
//default	async event void Foo.tx1(){}
//default	async event void Foo.rcv(){}
//default async event void Foo.tx2(){}
}





