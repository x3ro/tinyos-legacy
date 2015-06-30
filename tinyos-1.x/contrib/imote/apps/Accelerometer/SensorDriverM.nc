/*
 * Copyright (c) 2004, Intel Corporation
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 * Redistributions of source code must retain the above copyright notice,
 * this list of conditions and the following disclaimer.
 *
 * Redistributions in binary form must reproduce the above copyright notice,
 * this list of conditions and the following disclaimer in the documentation
 * and/or other materials provided with the distribution.
 *
 * Neither the name of the Intel Corporation nor the names of its contributors
 * may be used to endorse or promote products derived from this software
 * without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
 * LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 */

#include "app.h"
module SensorDriverM {

  provides {
    interface StdControl;
  }

  uses {
    interface HPLUART;
    interface HPLDMA;
    interface Memory;

    event result_t SampleAcquired(uint16 Tx, uint16 Ty, uint16 T);
    event result_t RawSamples(uint8 *Data, uint16 NumBytes);
  }
}

implementation
{

   #define UART_CHUNK_BYTES 18 	// Ta, Tb, Tc two bytes each
   #define INVALID_STATE 0xff
   #define NUM_BYTES_PER_COUNTER 2
   #define NUM_COUNTERS 3
      

   extern tTOSBufferVar *TOSBuffer __attribute__ ((C)); 
   uint8  Counters[NUM_COUNTERS][NUM_BYTES_PER_COUNTER];
   bool   CollectData;
   uint8  CurrentCounter, CurrentByte;
   char   temp[50];
   bool   started_uart;
   uint32 NumGetEvents;
   bool   led_state;
   uint8  temp_counter;
   
   typedef struct tUartBuffer {
      uint8  *data;
      bool   full;
   } tUartBuffer;

   tUartBuffer Buffers[2];
   uint16 UartChunkBytes;
   uint8 UsedBuffer;

void debug_msg (char *str) {

#if DEBUG_ON
   trace(DBG_USR1, str);
#endif
}

   /*
    * Controlling the sensor board
    */
   void InitSensor() {
      TM_SetPio(7);    
   }

   void StartSensor() {
      TM_ResetPio(7);    
   }

   void StopSensor() {
      TM_SetPio(7);    
   }

   /*
    * StdControl Interface
    */
   command result_t StdControl.init() {

       call HPLUART.setRate(eTM_B460800);
       call HPLUART.init();

       atomic {
          CollectData = false;
       }
       CurrentByte = CurrentCounter = INVALID_STATE;
       started_uart = false;
       InitSensor();
       NumGetEvents = 0;
       led_state = 0;
       temp_counter = 0;
       return SUCCESS;
   }

   command result_t StdControl.start() {
      uint8 *membuf;

      if (!started_uart) {
         // Create the buffers
         membuf = call Memory.alloc(UART_CHUNK_BYTES*2);
         atomic {
            UartChunkBytes = UART_CHUNK_BYTES;
            if (membuf == NULL) {
               // Can't allocate memory, just use the 32 byte RX buffer
               UartChunkBytes = 6;
               Buffers[0].data = TOSBuffer->UARTRxBuffer;
               Buffers[1].data = &(TOSBuffer->UARTRxBuffer[UartChunkBytes]);
            } else {
               Buffers[0].data = membuf;
               Buffers[1].data = &(membuf[UartChunkBytes]);
            }

            Buffers[0].full = false;
            Buffers[1].full = false; 
  
            // Assume UART always running for now, we drop data if app stops us
            UsedBuffer = 0;
         }
         call HPLDMA.DMAGet(Buffers[0].data, UartChunkBytes);
         started_uart = true;
      }
      if (!CollectData) {
         atomic {
            CollectData = true;
         }
         StartSensor();
      }
      return SUCCESS;
   }

   command result_t StdControl.stop() {
      if (CollectData) {
         atomic {
            CollectData = false;
         }
         StopSensor();
      }
      return SUCCESS;
   }

   /*
    * Process the data.  We get Tb, Tc, Td
    * (x channel pulse width) T1x = Tb
    * (y channel pulse width) T1y = Td - Tc
    * Period (shared for x & y) T = (Td + Tc - Tb)/2
    * We send Tx, Ty, T
    */ 
   void ProcessSample() {
      uint16 Tb, Tc, Td, Tx, Ty, T;
      Tb = (int) (Counters[0][0] << 7) | (Counters[0][1]);
      Tc = (int) (Counters[1][0] << 7) | (Counters[1][1]);
      Td = (int) (Counters[2][0] << 7) | (Counters[2][1]);

      Tx = Tb;
      Ty = Td - Tc;
      T = (Td + Tc - Tb) >> 1;
      signal SampleAcquired(Tx, Ty, T);
      //debug_msg("PS\r\n");
   }

   #define IsFirstByte(i) ((i & 0x80) == 0)
   #define CounterIndex(i) ((i >> 5) & 0x3)
   #define ByteIndex(i) ((i >> 7) & 1)
   #define GetFirstByteValue(value) (value & 0x1f)
   #define GetSecondByteValue(value) (value & 0x7f)
   #define LAST_COUNTER 2

   void task ProcessBuffer() {
      uint8 i;
      uint8 NextCounter;
      uint8 *data;
      uint8 BufferIndex;
      bool  NoData;

#if 0
      temp_counter++;
      if (temp_counter < 100) {
         TM_ResetPio(4);
         TM_ResetPio(5);
         TM_SetPio(6);
      } else if (temp_counter < 200) {
         TM_ResetPio(4);
         TM_SetPio(5);
         TM_ResetPio(6);
      } else {
         temp_counter = 0;
      }
#endif

      // Check if there is data to process
      NoData = false;
      atomic {
         if (Buffers[0].full) {
            data = Buffers[0].data;
            BufferIndex = 0;
         } else if (Buffers[1].full) {
            data = Buffers[1].data;
            BufferIndex = 1;
         } else {
            NoData = true;
         }
      }
 
      if (NoData) {
         debug_msg("PB1\r\n");
         return;
      }
     
#if RAW_SAMPLES		// don't process, just send out over the radio
      signal RawSamples(data, UartChunkBytes);
      Buffers[BufferIndex].full = false;
      return; 
#endif

      /* 
       * Data format : each sample has 3 counters, 2 bytes each
       *    byte format : 0 xx yyyyy  (byte 0) 
       *                  1 zzzzzzz   (byte 1)
       *    xx : is the counter index, zzzzzzzyyyyy is counter value
       * Right now, since the data rate is low, we can afford to check
       * the location of each byte, if the data rate goes higher, we
       * can use index just to sink on block basis
       */ 

#if 0
      sprintf(temp, "data %x, %x, %x, %x, %x, %x\r\n", data[0], data[1], 
              data[2], data[3], data[4], data[5]);
      debug_msg(temp);
#endif

      for(i=0; i<UartChunkBytes; i++) {
         if (CurrentCounter == INVALID_STATE) {
            // need to synch, wait for 1st byte of Tb
            if (!IsFirstByte(data[i])) {
#if 0
               sprintf(temp, "nt first byte, i = %d, data = %d\r\n", i, data[i]);
               debug_msg(temp);
#endif
               //debug_msg("PB2\r\n");
               continue;
            }
            if (CounterIndex(data[i]) != 0) {
               // check next byte
#if 0
               sprintf(temp, "not first byte, i = %d, data = %d\r\n", i, data[i]);
               debug_msg(temp);
#endif
               //debug_msg("PB3\r\n");
               continue;
            }
#if 0
            sprintf(temp, "first byte, i = %d, data = %d\r\n", i, data[i]);
            debug_msg(temp);
#endif
            CurrentCounter = 0;
            CurrentByte = 0;
            Counters[0][0] = data[i];	// in this case they match
            //debug_msg("PB4\r\n");
         } else {
            if (CurrentByte == 0) {
               // need to find byte1
               if (IsFirstByte(data[i])) {
                  // discontinuity
                  CurrentCounter = INVALID_STATE;
                  //debug_msg("PB5\r\n");
               } else {
                  // just get the current byte
#if 0
                  sprintf(temp, "next : i = %d, data = %d\r\n", i, data[i]);
                  debug_msg(temp);
#endif
                  Counters[CurrentCounter][1] = GetSecondByteValue(data[i]);
                  CurrentByte = 1;
                  if (CurrentCounter == LAST_COUNTER) {
                     // collected a sample, process the data and signal app
                     ProcessSample();
                     CurrentCounter = INVALID_STATE;  // reset counter
                     //debug_msg("PB6\r\n");
                  } else {
                     //debug_msg("PB12\r\n");
                  }
               }
            } else {
               // Current byte is 1, Expecting byte 0
               if (!IsFirstByte(data[i])) {
                  // discontinuity
                  CurrentCounter = INVALID_STATE;
                  //debug_msg("PB7\r\n");
               } else {
                  // check if counter is correct
                  NextCounter = CounterIndex(data[i]);
                  if ((NextCounter - CurrentCounter) == 1) {
                     CurrentCounter = NextCounter;
                     Counters[CurrentCounter][0] = GetFirstByteValue(data[i]);
                     CurrentByte = 0;
#if 0
                     sprintf(temp, "Next : i = %d, data = %d\r\n", i, data[i]);
                     debug_msg(temp);
#endif
                     //debug_msg("PB8\r\n");
                  } else {
                      CurrentCounter = INVALID_STATE;
                      //debug_msg("PB9\r\n");
                  }
               }
            }
         }
      }
      atomic {
         Buffers[BufferIndex].full = false;
      }
      return; 
   }

   async event uint8 * HPLDMA.DMAGetDone(uint8 *data, uint16 NumBytes) {
      uint8 OtherBuffer;

      if (!CollectData || (NumBytes != UartChunkBytes)) {
         // error condition, just restart
         return Buffers[UsedBuffer].data;
      }

#if 0
      temp_counter++;
      if (temp_counter < 100) {
         TM_ResetPio(4);
         TM_ResetPio(5);
         TM_SetPio(6);
      } else if (temp_counter < 200) {
         TM_ResetPio(4);
         TM_SetPio(5);
         TM_ResetPio(6);
      } else {
         temp_counter = 0;
      }
#endif

      if (UsedBuffer == 0) {
         OtherBuffer = 1;
      } else {
         OtherBuffer = 0;
      }

      // If other buffer is full, just keep overwriting the current buffer, otherwise swap
      if (Buffers[OtherBuffer].full == false) {
         Buffers[UsedBuffer].full = true;	// process this one
         UsedBuffer = OtherBuffer;		// Set the other one for next fill
      }

      post ProcessBuffer();	// trigger the processing in both cases
      return Buffers[UsedBuffer].data;
   }

   async event result_t HPLDMA.DMAPutDone(uint8 *data) {
      return SUCCESS;
   }
   
   async event result_t HPLUART.get(uint8 data){
       return SUCCESS;
   }

   async event result_t HPLUART.putDone(){
       return SUCCESS;
   }
  
}  
