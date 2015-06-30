// $Id: PhyRadioM.nc,v 1.4 2004/09/03 20:12:17 weiyeisi Exp $

/* Copyright (c) 2002 the University of Southern California.
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice and the following
 * two paragraphs appear in all copies of this software.
 *
 * IN NO EVENT SHALL THE UNIVERSITY OF SOUTHERN CALIFORNIA BE LIABLE TO ANY
 * PARTY FOR DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES
 * ARISING OUT OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE
 * UNIVERSITY OF SOUTHERN CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 *
 * THE UNIVERSITY OF SOUTHERN CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF SOUTHERN CALIFORNIA HAS NO
 * OBLIGATION TO PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR
 * MODIFICATIONS.
 *
 */
/* Authors:	Wei Ye
 * Date created: 1/21/2003
 * 
 * This is the physical layer that sends and receives a packet
 *   - accept any type and length (<= PHY_MAX_PKT_LEN in phy_radio_msg.h) of packet
 *   - sending a packet: encoding and byte spooling
 *   - receiving a packet: decoding, byte buffering
 *   - Optional CRC check (CRC calculation is based on code from Jason Hill)
 *   - interface to radio control and physical carrier sense
 *
 */

/**
 * @author Wei Ye
 */


//includes uartDebug;

module PhyRadioM
{
   provides {
      interface StdControl as PhyControl;
      interface RadioState as PhyState;
      interface PhyComm;
      interface PhyStreamByte;
   }
   uses {
      interface StdControl as RadControl;
      interface RadioState;
      interface RadioByte;
      interface StdControl as CodecControl;
      interface RadioEncoding as Codec;
      interface SignalStrength;
   }
}

implementation
{
#include "PhyRadioMsg.h"
#include "smacEvents.h"
#include "phyUartDebug.h"

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
   
   // type of RSSI samples
   enum {SIGNAL, NOISE};
   
   char state;
   uint8_t stateLock; // lock for state transition
   uint8_t pktLength; // pkt length including my header and trailer
   PhyPktBuf buffer1;  // 2 buffers for receiving and processing
   PhyPktBuf buffer2;
   char recvBufState;  // receiving buffer state
   char procBufState;  // processing buffer state
   char* procBufPtr;
   char* sendPtr;
   char* recvPtr;
   char* procPtr;
   uint8_t recvCount;
   uint8_t numEncoded;
   char txBuffer[3];
   uint8_t bufHead;
   uint8_t bufEnd;
   int16_t crcRx;     // CRC of received pkt
   int16_t crcTx;     // CRC of transmitted pkt
   uint16_t signalLevel;  // average signal strength of received pkts
   uint16_t noiseLevel;  // average noise floor
   uint8_t typeRSSI;  // type of RSSI sample
#ifdef PHY_TEST_RSSI
   uint8_t flagRSSI;  // flag to keep sampling RSSI
   uint8_t valueRSSI;  // for testing only
#endif
   
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

   int16_t update_crc(char data, int16_t crc)
   {
      char i;
      int16_t tmp;
      tmp = (int16_t)(data);
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
      char error; //, intEnabled;
      uint8_t len;
      len = (uint8_t)procPtr[0];
      if (crcRx != *(int16_t*)(procPtr + len - 2)) {
         error = 1;
      } else {
         error = 0;
         // update average signal strength
         signalLevel = (signalLevel + ((PhyPktBuf*)procPtr)->info.strength) >> 1;
         phyUartDebug_byte((uint8_t)(signalLevel>>8));
         phyUartDebug_byte((uint8_t)(signalLevel));
         // sample noise level
         typeRSSI = NOISE;
#ifdef PHY_TEST_RSSI
         valueRSSI = 0;  // for testing only
         flagRSSI = 1;  // for testing, only sample once
#endif
         call SignalStrength.sampleStart();
      }
      tmp = signal PhyComm.rxPktDone(procPtr, error);
      if (tmp) {
        atomic {
         if (recvBufState == BUSY) { // waiting for a free buffer
            procPtr = recvPtr;
            recvPtr = (char*)tmp;
            recvBufState = FREE;  // can start receive now
         } else {
            procPtr = NULL;
            procBufPtr = (char*)tmp;
            procBufState = FREE;
         }
        }
         if (procPtr) {  // have a buffered packet to signal
            if (!post packet_received()) {  // task queue is full
               procBufPtr = procPtr;  //drop packet
               procBufState = FREE;
               signal PhyComm.rxPktDone(NULL, 1); // signal in case MAC is waiting
            }
         }
      }
   }


   task void packet_sent()
   {
      signal PhyComm.txPktDone(sendPtr);
   }


   command result_t PhyControl.init()
   {
      state = IDLE;
      recvPtr = (char*)&buffer1;
      procBufPtr = (char*)&buffer2;
      recvBufState = FREE;
      procBufState = FREE;
      signalLevel = 0;
      noiseLevel = 0;
#ifdef PHY_TEST_RSSI
      flagRSSI = 0;  // for testing only
#endif
      call RadControl.init();
      // initialize UART debugging
      phyUartDebug_init();
      return SUCCESS;
   }


   command result_t PhyControl.start()
   {
      call RadControl.start();
      return SUCCESS;
   }
   
   
   command result_t PhyControl.stop()
   {
      call RadControl.stop();
      return SUCCESS;
   }
   
   
   command result_t PhyState.idle()
   {
      if (!lockAcquire(&stateLock)) return FAIL; // in state transition
      if (call RadioState.idle()) {
         state = IDLE;
         lockRelease(&stateLock); // release state lock
         return SUCCESS;
      }
      lockRelease(&stateLock); // release state lock
      return FAIL;
   }
   
   
   command result_t PhyState.sleep()
   {
      if (!lockAcquire(&stateLock)) return FAIL; // in state transition
      if (call RadioState.sleep()) {
         state = IDLE;
         lockRelease(&stateLock); // release state lock
         return SUCCESS;
      }
      lockRelease(&stateLock); // release state lock
      return FAIL;
   }


   command result_t PhyComm.txPkt(void* packet, uint8_t length)
   {
#ifdef PHY_TEST_RSSI
      // for testing noise level measurement
      if (flagRSSI == 1) {
         flagRSSI = 0; // stop RSSI sampling
         phyUartDebug_byte((uint8_t)(noiseLevel>>8));
         phyUartDebug_byte((uint8_t)noiseLevel);
         phyUartDebug_byte(0xb4);  // 180 stop symbol
      }
#endif
      if (length > PHY_MAX_PKT_LEN || length < PHY_MIN_PKT_LEN) return FAIL;
      if (!lockAcquire(&stateLock)) return FAIL; // in state transition
      if (!call RadioByte.startTx()) return FAIL; // radio is busy
      state = TRANSMITTING;
      sendPtr = (char*)packet;
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


   // default do-nothing event handler for PhyComm interface
   default event result_t PhyComm.txPktDone(void* packet)
   {
      return SUCCESS;
   }
   
   
   default event result_t PhyComm.startSymDetected(void* packet)
   {
      return SUCCESS;
   }
   
   
   default event void* PhyComm.rxPktDone(void* packet, char error)
   {
      return packet;
   }
   

   async event result_t Codec.encodeDone(char data)
   {
      txBuffer[bufEnd] = data;
      bufEnd++;
      return SUCCESS;
   }


   async event result_t Codec.decodeDone(char data, char error)
   {
      // one byte is decoded
      if (recvCount == 0) {  // first byte is packet length
         if (error == 1 || (uint8_t)data > PHY_MAX_PKT_LEN 
            || (uint8_t)data < PHY_MIN_PKT_LEN) {
            call RadioState.idle();
            state = IDLE;
            // signal received an erroneous packet with NULL buffer
            // unknown length (0) and error flag setting to 1
            signal PhyComm.rxPktDone(NULL, 1);
            return FAIL;
         }
         pktLength = (uint8_t)data;
         crcRx = 0;
         // start sampling signal strength
         phyUartDebug_byte(0xaa); // 170 start symbol
         typeRSSI = SIGNAL;
#ifdef PHY_TEST_RSSI
         flagRSSI = 0; // for testing -- only sample once
#endif
         call SignalStrength.sampleStart();
      }
      recvPtr[recvCount] = data;
      recvCount++;

      // pass data for upper layer to stream bytes (e.g. snooper)
      signal PhyStreamByte.rxByteDone(data);

      if (recvCount < pktLength - 1) {
         crcRx=update_crc(data, crcRx);
      } else if (recvCount == pktLength) { // Rx packet done
         if (procBufState == FREE) {  // have a free buffer, use it now
            procPtr = recvPtr;
            recvPtr = procBufPtr;
            recvBufState = FREE;
            if (post packet_received()) { // signal upper layer
               procBufState = BUSY;
            } else {  // task queue is full
               procBufPtr = procPtr;  //drop packet
               signal PhyComm.rxPktDone(NULL, 1); // signal in case MAC is waiting
            }
         } else {  // no buffer to use for Rx
            recvBufState = BUSY;
         }
         call CodecControl.init();
         call RadioState.idle();
         state = IDLE;
      }
      return SUCCESS;
   }


   // default do-nothing handler for PhyStreamByte
   default event result_t PhyStreamByte.rxByteDone(char data)
   {
      return SUCCESS;
   }


   event result_t RadioByte.txByteReady()
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
         // signal upper layer Tx done
         if (!post packet_sent()) {  // try to post task first
            signal PhyComm.txPktDone(sendPtr); // signal directly if can't post
         }
      }
      return SUCCESS;
   }


   event result_t RadioByte.startSymDetected()
   {
      // Phy must be in IDLE state, otherwise there is a bug
      if (stateLock) return FAIL; // in state transition
      if (state == IDLE && recvBufState == FREE) {
         state = RECEIVING;
         recvCount = 0;
         // signal MAC w/ receiving buffer so that it can put in timestamp
         signal PhyComm.startSymDetected(recvPtr);
         return SUCCESS;
      }
      return FAIL;
   }


   event result_t RadioByte.rxByteDone(char data)
   {
      if (stateLock) return FAIL; // in state transition
      if (state == RECEIVING) {
         call Codec.decode(data);
         return SUCCESS;
      }
      return FAIL;
   }


   async event result_t SignalStrength.sampleReady(uint16_t value)
   {
      // will take care of the situation that MAC tries to turn off the 
      // radio before sampling of noise level is done
      if (value == 0) return FAIL;
      if (typeRSSI == SIGNAL) { // RSSI of a receiving packet
         ((PhyPktBuf*)recvPtr)->info.strength = value; // put into pkt
         phyUartDebug_byte((uint8_t)(value>>8));
         phyUartDebug_byte((uint8_t)value);
         // don't update average signal strength until CRC is checked
      } else { // measuring noise floor
#ifndef PHY_TEST_RSSI
         // average with previous measurement
         noiseLevel = (noiseLevel + value) >> 1;
         phyUartDebug_byte((uint8_t)(noiseLevel>>8));
         phyUartDebug_byte((uint8_t)noiseLevel);
      }
      return FAIL; // stop sampling
#else
         // for testing only
         if (valueRSSI == 0) {
            valueRSSI = 1;
            noiseLevel = value;
            phyUartDebug_byte((uint8_t)(noiseLevel>>8));
            phyUartDebug_byte((uint8_t)noiseLevel);
         } else {
            noiseLevel = (noiseLevel + value) >> 1;
         }

      }
      if (flagRSSI == 1) return SUCCESS; // continue sampling
      else return FAIL; // stop sampling
#endif
   }


   default command result_t SignalStrength.sampleStart()
   {
      return FAIL;
   }

}  // end of implementation
