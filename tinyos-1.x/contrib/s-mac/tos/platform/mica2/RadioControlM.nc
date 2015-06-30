// $Id: RadioControlM.nc,v 1.14 2005/03/26 19:09:37 weiyeisi Exp $

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
/* Authors: Wei Ye, Honghui Chen
 * Date created: 1/21/2003
 *
 * This module implements the radio control functions:
 *   1) Put radio into different states:
 *   	a) idle; b) sleep; c) receive; d) transmit
 *   2) Start symbol detection in idle state
 *      (Partially based on CC1000RadioM.nc)
 *   3) Physical carrier sense
 * 
 */

/**
 * @author Wei Ye
 * @author Honghui Chen
 */


//includes uartDebug;

module RadioControlM
{
   provides {
      interface StdControl as RadControl;
      interface RadioState;
      interface CarrierSense;
      interface RadioByte;
      interface SignalStrength;
   }
   uses {
      interface StdControl as CC1000StdControl;
      interface CC1000Control;
      interface ADCControl;
      interface ADC as RSSIADC;
   }
}

implementation
{
// carrier sense threshold that determines a busy channel
#ifndef RADIO_BUSY_THRESHOLD
#define RADIO_BUSY_THRESHOLD 0xb5
#endif

   enum {
      // early warning threshold
      EW_THRESHOLD = RADIO_BUSY_THRESHOLD + 0x1b,
      NUM_EXT_BYTES = 3
   };

   char start[2] __attribute((C)) = {0x33, 0xcc};

   // radio states. INIT is a temperary state only at start up
   enum { INIT, SLEEP, IDLE, SYNC_START, RECEIVE, TRANSMIT };
   
   uint8_t state;        // radio state
   uint8_t stateLock;    // lock for state transition
   uint16_t carrSenTime; // carrier sense time
   uint16_t csVal1;      // first carrier sense sample
   uint16_t csValAve;    // average value of carrier sense
   uint8_t extFlag;      // carrier sense extension flag
   uint8_t nextByte;     // tx buffer
   uint8_t txCount;      // for start symbol tx
   uint8_t getRSSI;      // flag if set will return RSSI (signal strength)

   bool bManchesterBad;
   bool bInvertRxData;	// data inverted
   
   enum {
      //SYNC_BYTE = 0x33,
      //NSYNC_BYTE = 0xcc,
      SYNC_WORD = 0x33cc,
      NSYNC_WORD = 0xcc33
   };

   enum {
      PREAMBLE_LEN = 18,
      VALID_PRECURSOR = 5
   };

   uint8_t PreambleCount;  //  found a valid preamble
   uint8_t SOFCount;
   union {
      uint16_t W;
      struct {
         uint8_t LSB;
         uint8_t MSB;
      };
   } RxShiftBuf;
   uint8_t RxBitOffset;	// bit offset for spibus

   uint16_t LocalAddr;
   
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
   

   // initialize the radio
   command result_t RadControl.init()
   {
      //uartDebug_init();
      
      state = INIT;
      LocalAddr = TOS_LOCAL_ADDRESS;

      getRSSI = 0; // only get RSSI upon request
      call ADCControl.bindPort(TOS_ADC_CC_RSSI_PORT,TOSH_ACTUAL_CC_RSSI_PORT);
      call ADCControl.init();

      call CC1000StdControl.init();
      call CC1000Control.SelectLock(0x9); // Select MANCHESTER VIOLATION
      bInvertRxData = call CC1000Control.GetLOStatus(); //if need to invert Rcvd Data

      // set SPI clock pin as input -- clock provided by radio
      TOSH_MAKE_SPI_SCK_INPUT();
      
      call RadioState.idle();
      return SUCCESS;
   }
   
   
   command result_t RadControl.start()
   {
      call RadioState.idle();
      return SUCCESS;
   }
   
   
   command result_t RadControl.stop()
   {
      outp(0x00, SPCR);  // turn off SPI
      call CC1000StdControl.stop();
      state = SLEEP;
      stateLock = 0; // clear state lock
      return SUCCESS;
   }
   
   
   // set radio into idle state. Automatically detect start symbol
   command result_t RadioState.idle()
   {
      if (state == IDLE) return SUCCESS;
      if (!lockAcquire(&stateLock)) return FAIL; // in state transition
      // clear state variables
      PreambleCount = 0;
      SOFCount = 0;
      RxBitOffset = 0;
      RxShiftBuf.W = 0;
      carrSenTime = 0;
      if (state == SYNC_START) {
         state = IDLE;
         lockRelease(&stateLock); // release state lock
         return SUCCESS;
      }
      if (state == SLEEP) {  // wake up radio if in sleep state
         call CC1000StdControl.start();
         call CC1000Control.BIASOn();
      } else {
         cbi(SPCR, SPIE);	// disable SPI interrupt
         cbi(SPCR, SPE);   // disable SPI
      }
      call CC1000Control.RxMode(); //set radio to Rx mode
      // configure SPI for input
      TOSH_MAKE_MISO_INPUT();
      TOSH_MAKE_MOSI_INPUT();
      outp(0xc0, SPCR);  // start SPI and enable SPI interrupt

      state = IDLE;
      lockRelease(&stateLock); // release state lock
      return SUCCESS;
   }
   
   
   // set radio into sleep mode: can't Tx or Rx
   command result_t RadioState.sleep()
   {
      if (state == SLEEP) return SUCCESS;
      if (!lockAcquire(&stateLock)) return FAIL; // in state transition
      outp(0x00, SPCR);  // turn off SPI
      call CC1000StdControl.stop();

      state = SLEEP;
      lockRelease(&stateLock); // release state lock
      return SUCCESS;
   }
   
   
   // start sending a new packet. Automatically send start symbol first
   command result_t RadioByte.startTx()
   {
      char temp;
      if (!lockAcquire(&stateLock)) return FAIL; // in state transition
      cbi(SPCR, SPIE);	// disable SPI interrupt
      cbi(SPCR, SPE);   // disable SPI
      if (state == SLEEP) {  // wake up radio if in sleep state
         call CC1000StdControl.start();
         call CC1000Control.BIASOn();
      }
      nextByte = 0xaa; // buffer second byte
      txCount = 2;
      temp = inp(SPSR);  // clear possible pending SPI interrupt
      outp(0xaa, SPDR);  // put first byte into SPI data register

      //set radio to Tx mode
      call CC1000Control.TxMode();	// radio to tx mode
      TOSH_MAKE_MISO_OUTPUT();
      TOSH_MAKE_MOSI_OUTPUT();
      outp(0xc0, SPCR);  // enable SPI and SPI interrupt

      state = TRANSMIT;
      lockRelease(&stateLock); // release state lock
      return SUCCESS;
   }
   
   
   // send next byte
   command result_t RadioByte.txNextByte(char data)
   {
      nextByte = data;
      return SUCCESS;
   }


   // start carrier sense
   command result_t CarrierSense.start(uint16_t numBits)
   {
      if (state != IDLE) return FAIL;
      extFlag = 0;
      carrSenTime = numBits >> 3;  // now is counted by number of bytes
      csVal1 = 0x180;
      return SUCCESS;
   }
	

   // default do-nothing handler for carrier sense
   default event result_t CarrierSense.channelIdle()
   {
      return SUCCESS;
   }


   default event result_t CarrierSense.channelBusy()
   {
      return SUCCESS;
   }
   
   
   // Interrupt handler for SPI.
   // The signal handler disables globle interrupts by default.
   TOSH_SIGNAL(SIG_SPI)
   {
      uint8_t data;
      data = inp(SPDR);
      if (bInvertRxData) data = ~data;

      if (state == TRANSMIT) {
         outp(nextByte, SPDR);  // send buffered byte
         if (txCount < PREAMBLE_LEN) {
            nextByte = 0xaa;
            txCount++;
         } else if (txCount < PREAMBLE_LEN + sizeof(start)) {
            nextByte = start[txCount - PREAMBLE_LEN];
            txCount++;
         } else {
            signal RadioByte.txByteReady(); // ask a byte from upper layer
         }
      } else if (state == IDLE) {
         bManchesterBad = call CC1000Control.GetLock();
         if ((!bManchesterBad) && (data == 0xaa || data == 0x55)) {
            PreambleCount++;
            if (PreambleCount > VALID_PRECURSOR) {
               if (stateLock) return; // radio is in transition
               state = SYNC_START;
               if (carrSenTime > 0) {  // MAC is in Carrier Sense state
                  carrSenTime = 0;  // stop carrier sense
                  signal CarrierSense.channelBusy();
               }
            }
         } else {
	        PreambleCount = 0;
         }
         if (carrSenTime > 0) call RSSIADC.getData(); // carrier sense
      } else if (state == SYNC_START) {
         uint8_t i;
         if (data == 0xaa || data == 0x55) {
           SOFCount = 0;   //tolerant of bad bits in the preamble...
         } else {
            uint8_t usTmp;
            SOFCount++;
            switch (SOFCount) {
            case 1:
               RxShiftBuf.MSB = data;
               break;
            case 2:
               RxShiftBuf.LSB = data;
               if (RxShiftBuf.W == SYNC_WORD) {
                  if (stateLock) return; // radio is in transition
                  state = RECEIVE;
                  RxBitOffset = 0;
                  if (signal RadioByte.startSymDetected() == FAIL) {
                     call RadioState.idle();
                  }
               } 
               break;            
            case 3: 
               // bit shift the data into previous samples to find SOF
               usTmp = data;
               for(i=0;i<8;i++) {
                  RxShiftBuf.W <<= 1;
                  if(usTmp & 0x80)
                     RxShiftBuf.W |= 0x1;
                  usTmp <<= 1;
                  // check for SOF bytes
                  if (RxShiftBuf.W == SYNC_WORD) {
                     if (stateLock) return; // radio is in transition
                     state = RECEIVE;
                     RxBitOffset = 7-i;
                     RxShiftBuf.LSB = data;
                     if (signal RadioByte.startSymDetected()== FAIL) {
                        call RadioState.idle();
                     }
                     break;
                  }
               }
               break;
            default:
               // We didn't find it after a reasonable number of tries, so....
               call RadioState.idle();
               break;
            }
         }
      }else if (state == RECEIVE) {
         char Byte;
         RxShiftBuf.W <<=8;
         RxShiftBuf.LSB = data;
         Byte = (RxShiftBuf.W >> RxBitOffset);

         signal RadioByte.rxByteDone(Byte);
      }		
   }


   async event result_t RSSIADC.dataReady(uint16_t data)
   {
      // ADC got a sample of signal strength
      if (state == IDLE && carrSenTime > 0) {
         csValAve = (csVal1 + data) >> 1;
         if (csValAve < RADIO_BUSY_THRESHOLD) {
            carrSenTime = 0;
            signal CarrierSense.channelBusy();
         } else {
            csVal1 = data;
            carrSenTime--;
            if (carrSenTime == 0) {
               if (extFlag == 1) {  // already checked extended bytes
                  signal CarrierSense.channelIdle();
               } else {
                  if (data < EW_THRESHOLD) {
                     extFlag = 1;  // set flag for extended bytes
                     carrSenTime = NUM_EXT_BYTES;
                  } else {  // signal strength is very low
                     signal CarrierSense.channelIdle();
                  }
               }
            }
         }
      }
      
      if (getRSSI) { // upper layer wants signal strength
         if (signal SignalStrength.sampleReady(data) == FAIL) {
            getRSSI = 0;
            return FAIL;  // stop sampling
         }
      }

      return SUCCESS;
   }


   command result_t SignalStrength.sampleStart()
   {
      // start continuous sampling on signal strength
      if (call RSSIADC.getContinuousData()) {
         getRSSI = 1;
         return SUCCESS;
      } else {
         return FAIL;
      }
   }


   default async event result_t SignalStrength.sampleReady(uint16_t data)
   {
      // default handler for a signal strength sample
      getRSSI = 0;
      return FAIL;  // stops sampling
   }

}  // end of implementation
