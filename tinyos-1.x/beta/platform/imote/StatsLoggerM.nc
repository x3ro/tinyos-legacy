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
module StatsLoggerM {

   provides {
      interface StdControl;
      interface StatsLogger;
   }

   uses {
      interface Timer;
      interface Memory;
   }
}

implementation {

#define MY_TICK 10	// 10 ms

   uint32 StatCounters[NUM_TYPES];
   uint8  CounterSizes[NUM_TYPES];
   uint32 MyTime;
   uint32 StartTimes[NUM_TYPES];
   uint8  NumRunningTimers;
   bool   RunCounters;
   uint8  MaxLogSize;

   void DisplayStr(char *str) C_ROUTINE;

   void debug_msg (char *str) {
      DisplayStr(str);
   }

   void InitCounterSizes() {
      uint8 i;

      CounterSizes[MSEC_MOTE_ON] = 4;
      CounterSizes[MSEC_MOTE_TX] = 4;
      CounterSizes[MSEC_SENSOR_BOARD_ON] = 4;
      CounterSizes[MSEC_SENSOR_ANALOG_ON] = 4;
      CounterSizes[MSEC_NETWORK_FORMATION] = 4;
      CounterSizes[MSEC_PER_SENSOR_TRANSFER] = 4;
      CounterSizes[MSEC_PER_MOTE_TRANSFER] = 4;
      CounterSizes[MSEC_PER_CLUSTER_TRANSFER] = 4;
      CounterSizes[NUM_RT_SEND_DATA] = 2;
      CounterSizes[NUM_RT_RECV_DATA] = 2;
      CounterSizes[NUM_RT_SEND_NACK] = 2;
      CounterSizes[NUM_RT_RECV_NACK] = 2;
      CounterSizes[NUM_ROUTING_SEND] = 2;
      CounterSizes[NUM_ROUTING_RECV] = 2;
      CounterSizes[NUM_PS_SEND] = 2;
      CounterSizes[NUM_PS_RECV] = 2;
      CounterSizes[NUM_DS_SEND] = 2;
      CounterSizes[NUM_DS_RECV] = 2;
      CounterSizes[NUM_TOTAL_SEND] = 2;
      CounterSizes[NUM_TOTAL_RECV] = 2;
      CounterSizes[HOP_COUNT_TO_CH] = 2;
      CounterSizes[ID_OF_NEXT_HOP] = 2;
      CounterSizes[NUM_NM_SEND] = 2;
      CounterSizes[NUM_NM_RECV] = 2;
      CounterSizes[NUM_NP_SEND] = 2;
      CounterSizes[NUM_NP_RECV] = 2;
      CounterSizes[NUM_SF_SEND] = 2;
      CounterSizes[NUM_SF_RECV] = 2;

      MaxLogSize = 1;	// Num of fields
      for (i=0; i<NUM_TYPES; i++) {
         MaxLogSize+= CounterSizes[i] + 2;	// type, value, len
      }
   }

   void ResetCounters() {
      uint8 i;
      for (i=0; i<NUM_TYPES; i++) {
         StatCounters[i] = 0;
         StartTimes[i] = 0;
      }
   }

   command result_t StdControl.init() {
      ResetCounters();
      MyTime = 1;
      NumRunningTimers = 0;
      RunCounters = false;
      InitCounterSizes();
      return SUCCESS;
   }

   command result_t StdControl.start() {
      RunCounters = true;
      return SUCCESS;
   }

   command result_t StdControl.stop() {
      RunCounters = false;
      return SUCCESS;
   }

   command result_t StatsLogger.BumpCounter(uint8 counter_type, uint32 value) {
      if ((counter_type < NUM_TYPES) && RunCounters) {
         StatCounters[counter_type] += value;
      }   
      return SUCCESS;
   }

   command result_t StatsLogger.OverwriteCounter(uint8 counter_type, uint32 value) {
      if ((counter_type < NUM_TYPES) && RunCounters) {
         StatCounters[counter_type] = value;
      }   
      return SUCCESS;
   }

   command result_t StatsLogger.StartTimer(uint8 counter_type) {
      if ((counter_type < NUM_TYPES) && RunCounters) {
         if (NumRunningTimers == 0) {
            call Timer.start(TIMER_REPEAT, MY_TICK);
         }
         if (StartTimes[counter_type] == 0) {
            StartTimes[counter_type] = MyTime;
            NumRunningTimers++;
         }
      }
      return SUCCESS;
   }

   command result_t StatsLogger.StopTimerUpdateCounter(uint8 counter_type) {
      uint32 TimePassed;
      if ((counter_type < NUM_TYPES) && RunCounters) {
         if (StartTimes[counter_type] > 0) {
            // was a running counter, update the value
            TimePassed = (MyTime - StartTimes[counter_type]) * MY_TICK;
            StatCounters[counter_type] += TimePassed;

            // Stop the counter, update state
            NumRunningTimers--;
            StartTimes[counter_type] = 0;
            if (NumRunningTimers == 0) {
               call Timer.stop();
            }
         }
      }
      return SUCCESS;
   }

   command result_t StatsLogger.ResetCounters() {
      ResetCounters();
      if (NumRunningTimers > 0) {
         call Timer.stop();
         NumRunningTimers = 0;
      }
      return SUCCESS;
   }

   /*
    * Write up the buffer in the following format
    * Number of counters <1B> field
    * Type <1B>, len <1B>, value
    */
   command uint8 *StatsLogger.GetCounterBuffer(uint32 *BufferSize) {
      uint8 *membuf, *tempbuf;
      uint8 NumBytes, NumFields;
      uint8 i, type_size;

      membuf = call Memory.alloc(MaxLogSize);
      if (membuf == NULL) {
         return NULL;
      }

      NumBytes = 1;
      NumFields = 0;
      tempbuf = membuf + 1;	// first byte is the number of fields
      for (i=0; i<NUM_TYPES; i++) {
         if (StatCounters[i] > 0) {
            NumFields++;
            type_size = CounterSizes[i];
            NumBytes+= type_size + 2;

            tempbuf[0] = i;	// type
            tempbuf[1] = type_size;	//len
            tempbuf+= 2;
            switch (type_size) {
               case 1:
                  tempbuf[0] = (uint8) StatCounters[i];
                  tempbuf++; 
                  break;
               case 2:
                  tempbuf[0] = (uint8) (StatCounters[i] & 0xff);
                  tempbuf[1] = (uint8) ((StatCounters[i] >> 8) & 0xff);
                  tempbuf+= 2; 
                  break;
               case 4:
                  tempbuf[0] = (uint8) (StatCounters[i] & 0xff);
                  tempbuf[1] = (uint8) ((StatCounters[i] >> 8) & 0xff);
                  tempbuf[2] = (uint8) ((StatCounters[i] >> 16) & 0xff);
                  tempbuf[3] = (uint8) ((StatCounters[i] >> 24) & 0xff);
                  tempbuf+= 4; 
                  break;
            }
         }
      }
      membuf[0] = NumFields;

      *BufferSize = NumBytes; 
      return membuf;
   }

   command result_t StatsLogger.FreeCounterBuffer(uint8 *CounterBuffer) {
      call Memory.free(CounterBuffer);
      return SUCCESS;
   }

   event result_t Timer.fired() {
      MyTime++;
      return SUCCESS;
   }
}
