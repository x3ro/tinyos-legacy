/*                                                      tab:4
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
 *
 * Copyright (c) 2002-2005 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */
 
/**
 * A rewrite of the low-power-listening CC1000 radio stack.
 * This file contains the send and receive logic for the CC1000 radio.
 * It does not do any media-access control. It requests the channel
 * via the ready-to-send event (rts) and starts transmission on reception
 * of the clear-to-send command (cts). It listens for packets if the
 * listen() command is called, and stops listening when off() is called.
 *
 * This code has some degree of platform-independence, via the
 * CC1000Control, RSSIADC and SpiByteFifo interfaces which must be provided
 * by the platform. However, these interfaces may still reflect some
 * particularities of the mica2 hardware implementation.
 *
 * @author Philip Buonadonna
 * @author Jaein Jeong
 * @author Joe Polastre
 * @author David Gay
 * @author David Moss
 */

includes crc;
includes CC1000Const;

module CC1000SendReceiveM {
  provides {
    interface StdControl;
    interface BareSendMsg as Send;
    interface ReceiveMsg as Receive;
    interface RadioTimeStamping;
    interface ByteRadio;
    interface PacketAcknowledgements;
    interface MacControl;
    interface RadioCoordinator as RadioSendCoordinator;
    interface RadioCoordinator as RadioReceiveCoordinator;
  }
  
  uses {
    interface CC1000Control;
    interface SpiByteFifo;
    interface Rssi as RssiRx;
  }
}

implementation {

  norace uint8_t radioState;
  
  norace uint16_t count;

  uint16_t runningCrc;

  uint16_t rxShiftBuf;

  TOS_Msg rxBuf;

  TOS_Msg *rxBufPtr = &rxBuf;

  uint16_t preambleLength;

  TOS_Msg *txBufPtr;

  uint8_t nextTxByte;

  /** Flags */
  struct {
    bool ack : 1;
    bool txBusy : 1;
    uint8_t rxBitOffset : 3;
  } f; // f for flags
  
  
  /**
   * States
   */
  enum {
    /** Off */
    S_INACTIVE,

    /* Listening for packets */
    S_LISTEN,  

    /* Reception states */
    S_SYNC,
    S_RX,
    S_RECEIVED,
    S_SENDACK,

    /* Transmission states */
    S_TXPREAMBLE,
    S_TXSYNC,
    S_TXDATA,
    S_TXCRC,
    S_TXFLUSH,
    S_TXWAITFORACK,
    S_TXREADACK,
    S_TXDONE,
  };

  /**
   * Sync and Ack bytes
   */
  enum {
    SYNC_BYTE1 = 0x33,
    SYNC_BYTE2 = 0xCC,
    SYNC_WORD = SYNC_BYTE1 << 8 | SYNC_BYTE2,
    ACK_BYTE1 = 0xBA,
    ACK_BYTE2 = 0x83,
    ACK_WORD = ACK_BYTE1 << 8 | ACK_BYTE2,
    ACK_LENGTH = 16,
    MAX_ACK_WAIT = 18,
  };

  const uint8_t ackCode[5] = {0xAB, 
                              ACK_BYTE1, 
                              ACK_BYTE2, 
                              0xAA, 
                              0xAA};
  
  
  /***************** State Prototypes ****************/
  void enterInactiveState();
  void enterListenState();
  void enterSyncState();
  void enterRxState();
  void enterReceiveState();
  void enterAckState();
  void enterTxPreambleState();
  void enterTxSyncState();
  void enterTxDataState();
  void enterTxCrcState();
  void enterTxFlushState();
  void enterTxWaitForAckState();
  void enterTxReadAckState();
  void enterTxDoneState();
  
  
  /***************** Tx Prototypes ****************/
  void sendNextByte();
  void txPreamble();
  void txSync();
  void txData();
  void txCrc();
  void txFlush();
  void txWaitForAck();
  void txReadAck(uint8_t in);
  void txDone();
  
  task void signalPacketSent();


  /***************** Rx Prototypes ****************/
  void packetReceived();
  void packetReceiveDone();
  void listenData(uint8_t in);
  void syncData(uint8_t in);
  void rxData(uint8_t in);
  void ackData(uint8_t in);
  
  task void signalPacketReceived();
  
  
  /***************** StdControl Commands ****************/
  command result_t StdControl.init() {
    call SpiByteFifo.initSlave();
    call ByteRadio.setAck(TRUE);
    return SUCCESS;
  }

  command result_t StdControl.start() {
    atomic {
      f.ack = TRUE;
      f.txBusy = FALSE;
    }
    return SUCCESS;
  }

  command result_t StdControl.stop() {
    atomic enterInactiveState();
    return SUCCESS;
  }


  /***************** Send Commands ****************/
  command result_t Send.send(TOS_Msg *msg) {
    atomic {
      if(f.txBusy) {
        return FAIL;
      
      } else {
        f.txBusy = TRUE;
        txBufPtr = msg;
        call ByteRadio.setAck(txBufPtr->ack);
      }
    }

    signal ByteRadio.rts();

    return SUCCESS;
  }

  /***************** ByteRadio Commands ****************/
  async command void ByteRadio.cts() {
    // We're set to go! Start with our exciting preamble...
    enterTxPreambleState();
    call SpiByteFifo.writeByte(0xAA);
    call CC1000Control.txMode();
    call SpiByteFifo.txMode();
  }

  async command void ByteRadio.listen() {
    enterListenState();
    call CC1000Control.rxMode();
    call SpiByteFifo.rxMode();
    call SpiByteFifo.enableIntr();
  }

  async command void ByteRadio.off() {
    enterInactiveState();
    call SpiByteFifo.disableIntr();
  }

  async command bool ByteRadio.isFree() {
    return (radioState == S_INACTIVE 
        || radioState == S_LISTEN 
        || radioState == S_SYNC);
  }

  async command void ByteRadio.setAck(bool on) {
    atomic f.ack = on;
  }

  async command void ByteRadio.setPreambleLength(uint16_t bytes) {
    atomic preambleLength = bytes;
  }

  async command uint16_t ByteRadio.getPreambleLength() {
    atomic return preambleLength;
  }

  async command TOS_Msg *ByteRadio.getTxMessage() {
    return txBufPtr;
  }

  async command bool ByteRadio.syncing() {
    return radioState == S_SYNC;
  }

  /***************** PacketAcknowledgements Commands ****************/
  async command result_t PacketAcknowledgements.requestAck(TOS_Msg *msg) {
    msg->ack = TRUE;
    return SUCCESS;
  }

  async command result_t PacketAcknowledgements.noAck(TOS_Msg *msg) {
    msg->ack = FALSE;
    return SUCCESS;
  }

  async command bool PacketAcknowledgements.wasAcked(TOS_Msg *msg) {
    return msg->ack;
  }
  
  
  /***************** MacControl Commands ****************/
  /**
   * Enable acknowledgmenets (backwards compatibility)
   */
  async command void MacControl.enableAck() {
    call ByteRadio.setAck(TRUE);
  }
  
  /**
   * Disable acknowledgements (backwards compatibility)
   */
  async command void MacControl.disableAck() {
    call ByteRadio.setAck(FALSE);
  }
  
  
  /***************** RssiRx Events ***********************/
  async event void RssiRx.readDone(result_t result, uint16_t data) {
    if(result != SUCCESS) {
      rxBufPtr->strength = 0;
    
    } else {
      rxBufPtr->strength = data;
    }
  }
  
  /***************** SpiByteFifo Events ****************/
  async event result_t SpiByteFifo.dataReady(uint8_t data) {
    signal RadioSendCoordinator.blockTimer();
    signal RadioReceiveCoordinator.blockTimer();

    // Invert the data because the LO is high
    data = ~data;

    switch (radioState) {
      case S_TXPREAMBLE: txPreamble(); break;
      case S_TXSYNC: txSync(); break;
      case S_TXDATA: txData(); break;
      case S_TXCRC: txCrc(); break;
      case S_TXFLUSH: txFlush(); break;
      case S_TXWAITFORACK: txWaitForAck(); break;
      case S_TXREADACK: txReadAck(data); break;
      case S_TXDONE: txDone(); break;

      case S_LISTEN: listenData(data); break;
      case S_SYNC: syncData(data); break;
      case S_RX: rxData(data); break;
      case S_SENDACK: ackData(data); break;
    
      default: break;
    }
  
    return SUCCESS;
  }


  /***************** State Functions ****************/
  void enterInactiveState() {
    radioState = S_INACTIVE;
  }

  void enterListenState() {
    radioState = S_LISTEN;
    count = 0;
  }

  void enterSyncState() {
    radioState = S_SYNC;
    count = 0;
    rxShiftBuf = 0;
  }

  void enterRxState() {
    radioState = S_RX;
    rxBufPtr->length = sizeof rxBufPtr->data;
    count = 0;
    runningCrc = 0;
  }

  void enterReceivedState() {
    radioState = S_RECEIVED;
  }

  void enterAckState() {
    radioState = S_SENDACK;
    count = 0;
  }
  
  void enterTxPreambleState() {
    radioState = S_TXPREAMBLE;
    count = 0;
    runningCrc = 0;
    nextTxByte = 0xAA;
  }

  void enterTxSyncState() {
    radioState = S_TXSYNC;
  }

  void enterTxDataState() {
    radioState = S_TXDATA;
    // The count increment happens before the first byte is read from the
    // packet, so we subtract one from the real packet start point to
    // compensate.
    count = -1; 
  }

  void enterTxCrcState() {
    radioState = S_TXCRC;
  }
    
  void enterTxFlushState() {
    radioState = S_TXFLUSH;
    count = 0;
  }
    
  void enterTxWaitForAckState() {
    radioState = S_TXWAITFORACK;
    count = 0;
  }
    
  void enterTxReadAckState() {
    radioState = S_TXREADACK;
    rxShiftBuf = 0;
    count = 0;
  }
    
  void enterTxDoneState() {
    radioState = S_TXDONE;
  }
  
  
  /***************** Tx Functions ****************/
  void sendNextByte() {
    call SpiByteFifo.writeByte(nextTxByte);
    count++;
  }

  void txPreamble() {
    sendNextByte();
    if(count >= preambleLength) {
      nextTxByte = SYNC_BYTE1;
      enterTxSyncState();
    }
  }
  
  void txSync() {
    sendNextByte();
    nextTxByte = SYNC_BYTE2;
    enterTxDataState();
    signal RadioSendCoordinator.startSymbol(8, 0, txBufPtr); 
    signal RadioTimeStamping.transmittedSFD(0, txBufPtr); 
  }

  void txData() {
    sendNextByte();
    
    if(count < offsetof(TOS_Msg, data) + txBufPtr->length) {
      nextTxByte = ((uint8_t *)txBufPtr)[count];
      runningCrc = crcByte(runningCrc, nextTxByte);
      signal RadioSendCoordinator.byte(txBufPtr, (uint8_t)count);
      
    } else {
      nextTxByte = runningCrc;
      enterTxCrcState();
    }
  }

  void txCrc() {
    sendNextByte();
    nextTxByte = runningCrc >> 8;
    enterTxFlushState();
  }

  void txFlush() {
    sendNextByte();
    if(count > 3) {
      if(f.ack) {
        enterTxWaitForAckState();
      
      } else {
        call SpiByteFifo.rxMode();
        call CC1000Control.rxMode();
        enterTxDoneState();
      }
    }
  }

  void txWaitForAck() {
    sendNextByte();
    if(count == 1) {
      call SpiByteFifo.rxMode();
      call CC1000Control.rxMode();
    
    } else if(count > 3) {
      enterTxReadAckState();
    }
  }

  void txReadAck(uint8_t in) {
    uint8_t i;

    sendNextByte();

    for (i = 0; i < 8; i++) {
      rxShiftBuf <<= 1;
      if(in & 0x80) {
        rxShiftBuf |=  0x1;
      }
      in <<= 1;

      if(rxShiftBuf == ACK_WORD) {
        txBufPtr->ack = 1;
        enterTxDoneState();
        return;
      }
    }
    
    if(count >= MAX_ACK_WAIT) {
      txBufPtr->ack = 0;
      enterTxDoneState();
    }
  }
  
  void txDone() {
    post signalPacketSent();
    signal ByteRadio.sendDone();
  }
  
  
  task void signalPacketSent() {
    TOS_Msg *pBuf;

    atomic {
      pBuf = txBufPtr;
      f.txBusy = FALSE;
      enterListenState();
    }
    
    signal Send.sendDone(pBuf, SUCCESS);
  }
  
  
  /***************** Rx Functions ****************/
  /**
   * Listen for preamble bytes 
   */
  void listenData(uint8_t in) {
    bool preamble = (in == 0xAA || in == 0x55);

    if(preamble) {
      count++;
      if(count > CC1K_ValidPrecursor) {
        enterSyncState();
      }
      
    } else {
      count = 0;
    }
    
    signal ByteRadio.idleByte(preamble);
  }

  void syncData(uint8_t in) {
    // draw in the preamble bytes and look for a sync byte
    // save the data in a short with last byte received as msbyte
    //    and current byte received as the lsbyte.
    // use a bit shift compare to find the byte boundary for the sync byte
    // retain the shift value and use it to collect all of the packet data
    // check for data inversion, and restore proper polarity 
    // XXX-PB: Don't do this.

    if(in == 0xAA || in == 0x55) {
      // It is actually possible to have the LAST BIT of the incoming
      // data be part of the Sync Byte.  SO, we need to store that
      // However, the next byte should definitely not have this pattern.
      rxShiftBuf = in << 8;
      
    } else if(count++ == 0) {
      rxShiftBuf |= in;
      
    } else if(count <= 6) {
      uint16_t tmp;
      uint8_t i;

      // bit shift the data in with previous sample to find sync
      tmp = rxShiftBuf;
      rxShiftBuf = rxShiftBuf << 8 | in;

      for(i = 0; i < 8; i++) {
        tmp <<= 1;
        if(in & 0x80) {
          tmp  |=  0x1;
        }
          
        in <<= 1;
        // check for sync bytes
        if(tmp == SYNC_WORD) {
          enterRxState();
          signal ByteRadio.rx();
          f.rxBitOffset = 7 - i;
          signal RadioTimeStamping.receivedSFD(0);
          signal RadioReceiveCoordinator.startSymbol(8, f.rxBitOffset, rxBufPtr); 
          call RssiRx.read();
        }
      }
        
    } else {
      // We didn't find it after a reasonable number of tries, so....
      enterListenState();
    }
  }
  
  void rxData(uint8_t in) {
    uint8_t nextByte;

    // rxLength is the offset into a TOS_Msg at which the packet
    // data ends: it is NOT equal to the number of bytes received,
    // as there may be padding in the TOS_Msg before the packet.
    uint8_t rxLength = rxBufPtr->length + offsetof(TOS_Msg, data);

    // Reject invalid length packets
    if(rxLength > TOSH_DATA_LENGTH + offsetof(TOS_Msg, data)) {
      // The packet's screwed up, so just dump it
      enterListenState();
      signal ByteRadio.rxDone();
      return;
    }
    
    // Subtract one to start counting from 0
    signal RadioReceiveCoordinator.byte(rxBufPtr, (uint8_t)count-1);
    
    rxShiftBuf = rxShiftBuf << 8 | in;
    nextByte = rxShiftBuf >> f.rxBitOffset;
    ((uint8_t *)rxBufPtr)[count++] = nextByte;

    if(count <= rxLength) {
      runningCrc = crcByte(runningCrc, nextByte);
    }
    
    // Jump to CRC when we reach the end of data
    if(count == rxLength) {
      count = offsetof(TOS_Msg, crc);
    }

    if(count == (offsetof(TOS_Msg, crc) + sizeof(rxBufPtr->crc))) {
      packetReceived();
    }
  }

  void packetReceived() {
    rxBufPtr->crc = (rxBufPtr->crc == runningCrc);

    if(f.ack
           && rxBufPtr->crc 
           && (rxBufPtr->addr == TOS_LOCAL_ADDRESS 
               || rxBufPtr->addr == TOS_BCAST_ADDR)) {
      
      enterAckState();
      call CC1000Control.txMode();
      call SpiByteFifo.txMode();
      call SpiByteFifo.writeByte(0xAA);
      
    } else {
      packetReceiveDone();
    }
  }

  void ackData(uint8_t in) {
    if(++count >= ACK_LENGTH) { 
      call CC1000Control.rxMode();
      call SpiByteFifo.rxMode();
      packetReceiveDone();
    
    } else if(count >= ACK_LENGTH - sizeof(ackCode)) {
      call SpiByteFifo.writeByte(ackCode[count + sizeof(ackCode) - ACK_LENGTH]);
    }
  }
  
  void packetReceiveDone() {
    enterReceivedState();
    post signalPacketReceived();
  }
  
  
  task void signalPacketReceived() {
    TOS_Msg *pBuf;
    atomic {
      pBuf = rxBufPtr;
    }
    
    pBuf = signal Receive.receive(pBuf);
    
    atomic {
      if(pBuf) {
        rxBufPtr = pBuf;
      
      } else {
        rxBufPtr = &rxBuf;
      }
      
      enterListenState();
      signal ByteRadio.rxDone();
    }
  }
  
  /***************** Defaults ****************/
  default async event void RadioTimeStamping.transmittedSFD(uint16_t time, TOS_Msg* msgBuff) {
  }
  
  default async event void RadioTimeStamping.receivedSFD(uint16_t time) {
  }
  
  
  default async event void RadioSendCoordinator.startSymbol(uint8_t bitsPerBlock, uint8_t offset, TOS_MsgPtr msgBuff) {
  }

  default async event void RadioSendCoordinator.byte(TOS_MsgPtr msg, uint8_t byteCount) {
  }

  default async event void RadioSendCoordinator.blockTimer() {
  }
  
    
  default async event void RadioReceiveCoordinator.startSymbol(uint8_t bitsPerBlock, uint8_t offset, TOS_MsgPtr msgBuff) {
  }

  default async event void RadioReceiveCoordinator.byte(TOS_MsgPtr msg, uint8_t byteCount) {
  }

  default async event void RadioReceiveCoordinator.blockTimer() {
  }
}
