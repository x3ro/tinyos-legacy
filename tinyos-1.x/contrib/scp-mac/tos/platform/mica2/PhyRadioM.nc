/*
 * Copyright (C) 2003-2005 the University of Southern California.
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
 * This is the physical layer that sends and receives a packet
 *   - accept any type and length (<= PHY_MAX_PKT_LEN in phy_radio_msg.h) of packet
 *   - sending a packet: encoding and byte spooling
 *   - receiving a packet: decoding, byte buffering
 *   - Optional CRC check (CRC calculation is based on code from Jason Hill)
 *   - interface to radio control and physical carrier sense
 */

module PhyRadioM
{
   provides {
      interface StdControl as PhyControl;
      interface RadioState as PhyState;
      interface PhyPkt;
      interface PhyNotify;
      interface TxPreamble as PhyTxPreamble;
      interface PhyStreamByte;
   }
   uses {
      interface StdControl as RadControl;
      interface RadioState;
      interface RadioByte;
      interface TxPreamble as RadioTxPreamble;
      interface CsThreshold as RadioCsThresh;
      interface StdControl as CodecControl;
      interface RadioEncoding as Codec;
      interface RSSISample;
      interface StdControl as LTimeControl;
      interface GetSetU32 as LocalTime;
      interface Leds;
      interface UartDebug;
   }
}

implementation
{
#include "StdReturn.h"
#include "PhyRadioMsg.h"

   // Physical layer states
   enum {
      IDLE,
      RECEIVING,
      TRANSMITTING,
      TRANSMITTING_LAST,
      TRANSMITTING_DONE
   };
   
   // buffer states
   enum {FREE, BUSY};
   
   // type of RSSI measurement
   enum {POST_TX_NOISE, POST_RX_NOISE, SIGNAL};
   
   uint8_t state;
   uint8_t stateLock; // lock for state transition
   uint8_t pktLength; // pkt length including my header and trailer
   PhyPktBuf buffer1;  // 2 buffers for receiving and processing
   PhyPktBuf buffer2;
   uint8_t recvBufState;  // receiving buffer state
   uint8_t procBufState;  // processing buffer state
   uint8_t* procBufPtr;
   uint8_t* sendPtr;
   uint8_t* recvPtr;
   uint8_t* procPtr;
   uint8_t recvCount;
   uint8_t numEncoded;
   uint8_t txBuffer[3];
   uint8_t bufHead;
   uint8_t bufEnd;
   int16_t crcRx;     // CRC of received pkt
   int16_t crcTx;     // CRC of transmitted pkt
   uint8_t typeRSSI;  // type of RSSI sample
   
   static inline result_t lockAcquire(uint8_t* lock)
   {
      result_t tmp;
      atomic {
         if (*lock == 0) {
            *lock = 1;
            tmp = SUCCESS;
         } else {
            tmp = FAIL;
         }
      }
      return tmp;
   }
   
   static inline void lockRelease(uint8_t* lock)
   {
      *lock = 0;
   }

   uint16_t update_crc(uint8_t data, uint16_t crc)
   {
      uint8_t i;
      uint16_t tmp;
      tmp = (uint16_t)(data);
      crc = crc ^ (tmp << 8);
      for (i = 0; i < 8; i++) {
         if (crc & 0x8000)
            crc = crc << 1 ^ 0x1021;  // << is done before ^
         else
            crc = crc << 1;
         }
      return crc;
   }
	
   task void packet_received()
   {
      void* tmp;
      uint8_t error;
      uint8_t len;
      len = (uint8_t)procPtr[0];
      if (crcRx != *(uint16_t*)(procPtr + len - 2)) {
         error = PKT_ERROR;
      } else {
         error = PKT_RECV;
         call RadioCsThresh.update( ((PhyPktBuf*)procPtr)->info.strength, 
              ((PhyPktBuf*)procPtr)->info.noise );
      }
      tmp = signal PhyPkt.receiveDone(procPtr, error);
      if (tmp) {  // procBufState is still busy
        error = 0;
        atomic {
          if (recvBufState == BUSY) { // waiting for a free buffer
            procPtr = recvPtr;
            recvPtr = (uint8_t*)tmp;
            recvBufState = FREE;  // can start receive now
            if (!post packet_received()) {  // signal the pending packet
              error = 1; // task queue is full
              procBufPtr = procPtr;  //drop packet
              procBufState = FREE;
            }
          } else {
            procPtr = NULL;
            procBufPtr = (uint8_t*)tmp;
            procBufState = FREE;
          }
        }
        if (error) {  // can't post task
          signal PhyPkt.receiveDone(NULL, PKT_ERROR); // signal in case MAC is waiting
        }
      }
   }


   task void packet_sent()
   {
      signal PhyPkt.sendDone(sendPtr);
   }


   command result_t PhyControl.init()
   {
      state = IDLE;
      recvPtr = (uint8_t*)&buffer1;
      procBufPtr = (uint8_t*)&buffer2;
      recvBufState = FREE;
      procBufState = FREE;
      call RadControl.init();  // initialize radio
      call LTimeControl.init();  // initialize local system time
      call Leds.init();  // initialize LED debugging, only yellow is used
      call UartDebug.init(); // initialize UART debugging
      return SUCCESS;
   }


   command result_t PhyControl.start()
   {
      call RadControl.start();
      call LTimeControl.start();
      call Leds.yellowOn();
      return SUCCESS;
   }
   
   
   command result_t PhyControl.stop()
   {
      call RadControl.stop();
      return SUCCESS;
   }
   
   
  command int8_t PhyState.idle()
  {
    // put radio into idle state
    // if wakes up from sleep, may not be immediately done
    
    int8_t result;
    if (!lockAcquire(&stateLock)) return FAILURE; // in state transition
    result = call RadioState.idle();
    if (result == FAILURE) {  // failed to wake up radio
      lockRelease(&stateLock); // release state lock
    } else if (result == SUCCESS_DONE) {
      state = IDLE;
      lockRelease(&stateLock); // release state lock
      call Leds.yellowOn();
    } else if (result == SUCCESS_WAIT) {  // wait for wakeupDone signal
      state = IDLE;
      call Leds.yellowOn();
    }
    return result;
  }
  
  
  async event result_t RadioState.wakeupDone()
  {
    // Radio wakeup is done -- it's stable now
    lockRelease(&stateLock); // release state lock
    signal PhyState.wakeupDone();
    return SUCCESS;
  }
    

  default async event result_t PhyState.wakeupDone()
  {
    // default do-nothing handler
    return SUCCESS;
  }
  
   
  command result_t PhyState.sleep()
  {
    if (!lockAcquire(&stateLock)) return FAIL; // in state transition
    if (call RadioState.sleep()) {
       state = IDLE;
       lockRelease(&stateLock); // release state lock
       call Leds.yellowOff();
       return SUCCESS;
    }
    lockRelease(&stateLock); // release state lock
    return FAIL;
  }


  command uint8_t PhyState.get()
  {
    // get radio state
    return call RadioState.get();
  }


   command result_t PhyPkt.send(void* packet, uint8_t length, uint16_t addPreamble)
   {
      if (length > PHY_MAX_PKT_LEN || length < PHY_MIN_PKT_LEN) return FAIL;
      if (!lockAcquire(&stateLock)) return FAIL; // in state transition
      if (!call RadioByte.startTx(addPreamble)) {
        lockRelease(&stateLock); // release state lock
        return FAIL; // radio is busy
      }
      state = TRANSMITTING;
      sendPtr = (uint8_t*)packet;
      ((PhyHeader*)sendPtr)->length = length;  // fill my header field
      pktLength = length;
      // encode first byte of the packet
      bufHead = 0;
      bufEnd = 0;
      call Codec.encode(sendPtr[0]);
      numEncoded = 1;
      crcTx=update_crc(sendPtr[0], 0);
      lockRelease(&stateLock); // release state lock
      return SUCCESS;
   }


   // default do-nothing event handler for PhyPkt interface
   default async event result_t PhyNotify.startSymSent(void* packet)
   {
      return SUCCESS;
   }
   
   
   default event result_t PhyPkt.sendDone(void* packet)
   {
      return SUCCESS;
   }
   
   
   default async event result_t PhyNotify.startSymDetected(void* packet, uint8_t bitOffset)
   {
      return SUCCESS;
   }
   
   
   default event void* PhyPkt.receiveDone(void* packet, uint8_t error)
   {
      return packet;
   }
  
  command result_t PhyTxPreamble.preload(uint16_t length)
  {
    return SUCCESS;
  }
  
  command result_t PhyTxPreamble.start(uint16_t length)
  {
    if (length == 0) return FAIL;
    if (!lockAcquire(&stateLock)) return FAIL; // in state transition
    if (!call RadioTxPreamble.start(length)) {
      lockRelease(&stateLock); // release state lock
      return FAIL; // radio is busy
    }
    state = TRANSMITTING;
    lockRelease(&stateLock); // release state lock
    return SUCCESS;
  }
  
  
  async event void RadioTxPreamble.done()
  {
    if (stateLock) return; // in state transition
    state = IDLE;
    signal PhyTxPreamble.done();
  }
  
  
  default async event void PhyTxPreamble.done()
  {
    // default do-nothing handler
  }
  
  
   async event result_t Codec.encodeDone(uint8_t data)
   {
      txBuffer[bufEnd] = data;
      bufEnd++;
      return SUCCESS;
   }


   async event result_t Codec.decodeDone(uint8_t data, uint8_t error)
   {
      // one byte is decoded
      if (recvCount == 0) {  // first byte is packet length
         if (error == 1 || (uint8_t)data > PHY_MAX_PKT_LEN 
            || (uint8_t)data < PHY_MIN_PKT_LEN) {
            call RadioState.idle();
            state = IDLE;
            // signal received an erroneous packet with NULL buffer
            // unknown length (0) and error flag setting to 1
            signal PhyPkt.receiveDone(NULL, PKT_ERROR);
            return FAIL;
         }
         pktLength = (uint8_t)data;
         crcRx = 0;
         // sample signal strength
         typeRSSI = SIGNAL;
         call RSSISample.get();
      }
      recvPtr[recvCount] = data;

      // pass data for upper layer to stream bytes (e.g. snooper)
      signal PhyStreamByte.rxDone(recvPtr, recvCount);

      recvCount++;
      if (recvCount < pktLength - 1) {
         crcRx = update_crc(data, crcRx);
      } else if (recvCount == pktLength) { // Rx packet done
         call CodecControl.init();
         call RadioState.idle();
         state = IDLE;
         // sample noise level
         typeRSSI = POST_RX_NOISE;
         call RSSISample.get();
      }
      return SUCCESS;
   }


   // default do-nothing handler for PhyStreamByte
   default event void PhyStreamByte.rxDone(uint8_t* buffer, uint8_t byteIdx)
   {
   }


   async event result_t RadioByte.txByteReady()
   {
      // radio asks a byte to transmit
      if (stateLock) return FAIL; // in state transition
      if(state == TRANSMITTING) {
         call RadioByte.txNextByte(txBuffer[bufHead]);
         bufHead++;
         //now check if that was the last byte
         if (bufHead == bufEnd) {
            bufHead = 0;
            bufEnd = 0;
            if (numEncoded < pktLength) {
               if(numEncoded < pktLength - 2){
                  crcTx=update_crc(sendPtr[numEncoded], crcTx);	
               }
               call Codec.encode(sendPtr[numEncoded]);
               numEncoded++;
               if(numEncoded == pktLength - 2){
                  *(int16_t*)(sendPtr + pktLength - 2) = crcTx;
               }
            } else {
               call Codec.encode_flush();
               if (bufHead == bufEnd) {
                  // tx is done
                  state = TRANSMITTING_LAST;
               }
            }
         }	
      } else if (state == TRANSMITTING_LAST) {
         state = TRANSMITTING_DONE;
      } else if (state == TRANSMITTING_DONE) {
         call RadioState.idle();
         state = IDLE;
         // don't use noise samples after Tx, since collision may happen
         // this is for keep transitter silent for the same time, so
         // that the receiver can take noise samples
         typeRSSI = POST_TX_NOISE;
         call RSSISample.get();
      }
      return SUCCESS;
   }


  async event result_t RadioByte.startSymSent()
  {
    // just sent out start symbol, signal for putting outgoing timestamp
    signal PhyNotify.startSymSent(sendPtr);
    return SUCCESS;
  }


  async event result_t RadioByte.startSymDetected(uint8_t bitOffset)
  {
    // Phy must be in IDLE state, otherwise there is a bug
    if (stateLock) return FAIL; // in state transition
    if (state == IDLE && recvBufState == FREE) {
      state = RECEIVING;
      recvCount = 0;
      // put in timestamp in 1ms resolution
      ((PhyPktBuf*)recvPtr)->info.timestamp = call LocalTime.get();
      // signal upper layer
      signal PhyNotify.startSymDetected(recvPtr, bitOffset);
      return SUCCESS;
    }
    return FAIL;
  }


   async event result_t RadioByte.rxByteDone(uint8_t data)
   {
      if (stateLock) return FAIL; // in state transition
      if (state == RECEIVING) {
         call Codec.decode(data);
         return SUCCESS;
      }
      return FAIL;
   }


  async event void RSSISample.ready(uint16_t value)
  {
    // Got a sample of signal or noise level
    if (typeRSSI == SIGNAL) {  // signal strength of a receiving packet
      ((PhyPktBuf*)recvPtr)->info.strength = value;  // put into pkt
    } else if (typeRSSI == POST_TX_NOISE) {  // noise after Tx
      // signal Tx msg done
      if (!post packet_sent()) {  // task queue is full
        signal PhyPkt.sendDone(sendPtr); // signal directly
      }
    } else if (typeRSSI == POST_RX_NOISE) {
      // signal Rx msg done
      ((PhyPktBuf*)recvPtr)->info.noise = value;  // put into pkt
      if (procBufState == FREE) {  // have a free buffer, use it now
        procPtr = recvPtr;
        recvPtr = procBufPtr;
        // recvBufState = FREE;  // not set as busy during Rx
        if (post packet_received()) { // signal upper layer
           procBufState = BUSY;
        } else {  // task queue is full
           procBufPtr = procPtr;  //drop packet
           signal PhyPkt.receiveDone(NULL, PKT_ERROR); // signal in case MAC is waiting
        }
      } else {  // no buffer to use for Rx
        recvBufState = BUSY;
      }
    }
  }


  default command result_t RSSISample.get()
  {
    return FAIL;
  }

}  // end of implementation
