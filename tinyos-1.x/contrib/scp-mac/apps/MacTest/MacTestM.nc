/*
 * Copyright (C) 2005 the University of Southern California.
 * All rights reserved.
 *
 * This program is free software; you can redistribute it and/or modify it
 * under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation; either version 2.1 of the License, or (at
 * your option) any later version.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
 * or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public
 * License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program; if not, write to the Free Software Foundation,
 * Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301, USA.
 *
 * In addition to releasing this program under the LGPL, the authors are
 * willing to dual-license it under other terms. You may contact the authors
 * of this project by writing to Wei Ye, USC/ISI, 4676 Admirality Way, Suite 
 * 1001, Marina del Rey, CA 90292, USA.
 */
/*
 * Authors: Wei Ye
 *
 * This application is a generic test of MAC functionalities
 */

module MacTestM
{
  provides interface StdControl;
  uses {
    interface StdControl as MacStdControl;
    interface MacMsg;
    interface GetSetU8 as RadioTxPower;
    interface RadioEnergy;
    interface GetSetU32 as LocalTime;
    interface Timer as TxTimer;
    interface Leds;
  }
}

implementation
{
  // test mode
  typedef enum {
     BROADCAST,
     UNICAST
  } TxMode;

  TxMode txMode;
  uint16_t unicastId;    // where to send my unicast msgs.
  uint8_t txSeqNo;       // sequence no of tx msgs
  uint8_t numTxBcast;    // number of broadcast Tx
  uint8_t numTxUcast;    // number of unicast Tx
  uint32_t lastTxTime;   // time when my last transmission is done
  RadioTime radioTimeTx;  // radio energy measurement until last transmission
  uint16_t numRxBcast;   // unmber of received broadcast msgs
  uint16_t numRxUcast;   // number of received msgs
  uint32_t lastRxTime;   // time when my last pkt is received
  uint16_t lastRxSignal; // signal strength of last received pkt
  uint16_t lastRxNoise;  // noise level after last received pkt
  RadioTime radioTimeRx;  // radio energy measurement until last reception
  bool radioBusy;  // flag
  bool txPending;  // flag
  AppPkt dataPkt;        // message to be sent
  
  task void sendMsg();
  
  command result_t StdControl.init()
  {
#ifdef TST_UNICAST_ONLY
    txMode = UNICAST;
#else
    txMode = BROADCAST;
#endif
#ifdef TST_UNICAST_ADDR
    unicastId = TST_UNICAST_ADDR;
#else
    if (TOS_LOCAL_ADDRESS == TST_MAX_NODE_ID) {
      unicastId = TST_MIN_NODE_ID;
    } else {
      unicastId = TOS_LOCAL_ADDRESS + 1;
    }
#endif
    txSeqNo = 0;
    numTxBcast = 0;
    numTxUcast = 0;
    lastTxTime = 0;
    numRxBcast = 0;
    numRxUcast = 0;
    lastRxTime = 0;
    radioBusy = FALSE;
    txPending = FALSE;

    call MacStdControl.init();   // initialize MAC and lower layers
#ifdef RADIO_TX_POWER
    call RadioTxPower.set(RADIO_TX_POWER);
#endif
    call Leds.init();
    return SUCCESS;
  }
  
  
  command result_t StdControl.start()
  {
    call MacStdControl.start();
    call RadioEnergy.startMeasure();
#ifndef TST_RECEIVE_ONLY
    if (TST_MSG_PERIOD == 0) {
      post sendMsg();
    } else {
      call TxTimer.start(TIMER_REPEAT, TST_MSG_PERIOD);
    }
#endif
    return SUCCESS;
  }
  
  
  command result_t StdControl.stop()
  {
    call TxTimer.stop();
    call MacStdControl.stop();
    call RadioEnergy.stopMeasure();
    return SUCCESS;
  }


  task void sendMsg()
  {
    // construct and send a new message
    
    uint16_t toAddr;
    dataPkt.hdr.seqNo = txSeqNo;     // num of tx accepted by MAC layer
    dataPkt.hdr.numTxBcast = numTxBcast;
    dataPkt.hdr.numTxUcast = numTxUcast;
    dataPkt.hdr.numRxBcast = numRxBcast;  // num of received broadcast pkts
    dataPkt.hdr.numRxUcast = numRxUcast;  // num of received unicast pkts
    dataPkt.hdr.lastTxTime = lastTxTime;  // time when last tx is done
    dataPkt.hdr.lastRxTime = lastRxTime;  // time when last pkt is received
    dataPkt.hdr.lastRxSignal = lastRxSignal; // signal strength of last Rx pkt
    dataPkt.hdr.lastRxNoise = lastRxNoise; // noise level after last Rx pkt
    *((RadioTime*)(&(dataPkt.data[0]))) = radioTimeTx;
    *((RadioTime*)(&(dataPkt.data[0])) + 1) = radioTimeRx;
    
    if (txMode == BROADCAST) {
      toAddr = TOS_BCAST_ADDR;
    } else {
      toAddr = unicastId;
    }
    if (call MacMsg.send(&dataPkt, sizeof(dataPkt), toAddr) == SUCCESS) {
      radioBusy = TRUE;
    }
  }
  
  
  event result_t TxTimer.fired()
  {
    // tx timer fired
    
    call Leds.yellowToggle();
#ifdef TST_RECEIVE_ONLY
    call RadioEnergy.stopMeasure();
#endif
    if (!radioBusy) {
      post sendMsg();
    } else {
      txPending = TRUE;
    }
    return SUCCESS;
  }
    
  
  event void MacMsg.sendDone(void* msg, result_t result)
  {
    // transmission is done
    
    RadioTime *energyTime;
    call Leds.redToggle();
    radioBusy = FALSE;
    lastTxTime = call LocalTime.get();
    energyTime = call RadioEnergy.get();
    radioTimeTx = *energyTime;
#ifndef TST_RECEIVE_ONLY
    if (((MacHeader*)msg)->toAddr == TOS_BCAST_ADDR) {  // broadcast
      numTxBcast++;
      txSeqNo++;
#ifndef TST_BROADCAST_ONLY
      txMode = UNICAST;
#endif
    } else {  // unicast
      numTxUcast++;
      txSeqNo++;
#ifndef TST_UNICAST_ONLY
      txMode = BROADCAST;
#endif
    }

#ifdef TST_NUM_MSGS
    if (txSeqNo >= TST_NUM_MSGS) {  // sent all messages
      call TxTimer.stop();
      call RadioEnergy.stopMeasure();
      return;
    }
#endif
    // schedule next tx
    if (TST_MSG_PERIOD == 0) {  // send messages back to back
      post sendMsg();
    } else {
      if (txPending) {  // message wait for tx
        txPending = FALSE;
        post sendMsg();
      }
    }
#endif  // TST_RECEIVE_ONLY
  }
  
  
  event void* MacMsg.receiveDone(void* msg)
  {
    // received a message
    
    AppPkt* pkt;
    RadioTime *energyTime;

    pkt = (AppPkt*)msg;
    call Leds.greenToggle();
    lastRxTime = call LocalTime.get();
    lastRxSignal = ((PhyPktBuf*)msg)->info.strength;
    lastRxNoise = ((PhyPktBuf*)msg)->info.noise;
    energyTime = call RadioEnergy.get();
    radioTimeRx = *energyTime;
    if (((MacHeader*)msg)->toAddr == TOS_BCAST_ADDR) {
      numRxBcast++;
    } else {  // got a unicast msg
      numRxUcast++;
    }
#if defined(TST_RECEIVE_ONLY) && defined(TST_REPORT_DELAY)
    // schedule timer to report results
    if (call TxTimer.getRemainingTime() == 0) {
      call TxTimer.start(TIMER_REPEAT, TST_REPORT_DELAY);
    } else {
      call TxTimer.setRemainingTime(TST_REPORT_DELAY);
    }
#endif
    return msg;
  }

}  // end of implementation

