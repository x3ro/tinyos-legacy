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
module AccelerometerM {

  provides {
    interface StdControl;
    event result_t SampleAcquired(uint16 Tx, uint16 Ty, uint16 T);
    event result_t RawSamples(uint8 *Data, uint16 NumBytes);
  }

  uses {
    interface StdControl as NetworkControl;
    interface StdControl as SensorControl;
    interface NetworkCommand;
    interface NetworkPacket;
#if HARDWIRED_NETWORK
    interface NetworkHardwired;
#endif
    interface Leds8;
    interface Timer;
  }
}

implementation
{

// FWD DEC
task void SendSamples();

#define TOTAL_CONNECTIONS 20

#define MAX_OUTSTANDING_PACKETS 8
#define MAX_NUM_SAMPLES 20
#define TIMER_TICK 10

/*
 * Commands
 */
#define CMD_START 0	// Start sending data, extra info = # samples / packet
#define CMD_STOP  1	// Stop sending data

typedef struct tTopology {
   uint32 slave;
   uint32 master;
} tTopology;

typedef struct tRequestPacketHeader {
   uint8 cmd;
   uint8 info1;
   uint8 info2;
   uint8 info3;
} tRequestPacketHeader;

typedef struct tSample {
   uint16 Tx;
   uint16 Ty;
   uint16 T;
} tSample;

   uint32 ThisNodeID;
   uint16 SamplesPerPacket;
   bool   SendingData;
   uint8  NumOutstandingPackets;
   tSample Samples[MAX_NUM_SAMPLES];
   uint8  Head, Tail, NumSamples;
   uint32 Destination;
   char temp[50];
   uint32 NumPacketsSent;
   uint8  SkipSamples;
   uint8  Skipped;
   uint8  MyTime;
   bool   FlushSamples;
   bool   Flushed;
   uint32 SampleCount;

#if HARDWIRED_NETWORK
    tTopology Connections[TOTAL_CONNECTIONS];
    uint8  NumConnections;
#endif

void debug_msg (char *str) {

#if DEBUG_ON
   trace(DBG_USR1, str);
#endif
}

   /*
    * StdControl Interface
    */
   command result_t StdControl.init() {

      result_t ok;
      uint8 i;
      ok = call NetworkControl.init();
      call NetworkCommand.SetAppName("Accelerometer");
      call NetworkPacket.Initialize();
      SamplesPerPacket = 1;
      Head = Tail = NumSamples = 0;
      NumPacketsSent = 0;
      Destination = 0;
      SkipSamples = 0;
      Skipped = 0;
      Flushed = false;
      SampleCount = 0;

#if HARDWIRED_NETWORK
      call NetworkHardwired.init();

      for (i = 0; i < TOTAL_CONNECTIONS; i++) {
         Connections[i].slave = 0;
         Connections[i].master = 0;
      }

      Connections[0].slave = 0x86326;
      Connections[0].master = 0x86335;
      Connections[1].slave = 0x86356;
      Connections[1].master = 0x86335;
      Connections[2].slave = 0x86342;
      Connections[2].master = 0x86335;

      NumConnections = 3;
      call NetworkHardwired.SetRootNode(0x86335);
#endif

      return ok;
   }

   command result_t StdControl.start() {

      result_t ok;
      uint8 i;

      ok = call NetworkControl.start();

      call NetworkCommand.GetMoteID(&ThisNodeID);
      call NetworkCommand.SetProperty(NETWORK_PROPERTY_APP_STREAMING_ACCEL);
      TM_DisableDeepSleep(TM_DEEPSLEEP_APLICATION_ID_2);
      call SensorControl.init();

#if HARDWIRED_NETWORK
      for (i=0; i < NumConnections; i++) {
         call NetworkHardwired.AddConnection(Connections[i].master, 
                                             Connections[i].slave);
      }

      call NetworkHardwired.start();
#endif

#if DEBUG_ON
      call Timer.start(TIMER_REPEAT, 1000);
#endif

      debug_msg("Started Accelerometer\r\n");
      return ok;
   }

   command result_t StdControl.stop() {

      result_t ok;
    
      ok = call NetworkControl.stop();

      return ok;
   }

   /*
    * NetworkPacket interface
    */
   event result_t NetworkPacket.Receive(uint32 Source,
                                        uint8  *Data,
                                        uint16 Length) {

      tRequestPacketHeader *Hdr;
      Hdr = (tRequestPacketHeader *) Data;
      switch (Hdr->cmd) {
         case CMD_START:
            sprintf(temp, "Received Collect Request from %5x\r\n", Source);
            debug_msg(temp);

            SendingData = true;
            call SensorControl.start();
            Destination = Source;
            SamplesPerPacket = Hdr->info1;
            SkipSamples = Hdr->info2;
            FlushSamples = true;
            break;

         case CMD_STOP:
            SendingData = false;
            call SensorControl.stop();
            break;
      }
     
      return SUCCESS;
   }

   event result_t NetworkPacket.SendDone(char *data) {
      call NetworkPacket.ReleaseBuffer(data);
      Flushed = false;
#if (!RAW_SAMPLES)
      NumOutstandingPackets--;
      if (NumSamples >= SamplesPerPacket) {
         post SendSamples();
      }
#endif
      
      return SUCCESS;
   }

   /*
    * NetworkCommand interface
    */
   event result_t NetworkCommand.CommandResult( uint32 Command, uint32 value) {

      switch(Command) {
      case COMMAND_NEW_NODE_CONNECTION:
         debug_msg("Connected\r\n");
         break;
          
      case COMMAND_NODE_DISCONNECTION:
         if (value == Destination) {
            // Disconnected from collector, stop
            SendingData = false;
            call SensorControl.stop();
            debug_msg("DisConnected\r\n");
         }
         break;
      }

      return SUCCESS;
   }
   
   task void SendSamples() {
      uint8 *Packet;
      tSample *SamplePtr;
      uint8 i;
      uint8 tempHead;
      result_t status;

      if (FlushSamples && !Flushed) {
         atomic{
            Head = 0;
            Tail = 0;
            NumSamples = 0;
            Skipped = 0;
            FlushSamples = false;
            Flushed = true;
         }
         return;
      }
      //debug_msg("ss\r\n");
            
      if (NumOutstandingPackets >= MAX_OUTSTANDING_PACKETS) {
         return;
      }

      if (NumSamples >= SamplesPerPacket) {
         Packet = call NetworkPacket.AllocateBuffer(SamplesPerPacket*sizeof(tSample)); 
         if (Packet == NULL) {
            return;
         }
         tempHead = Head;
         SamplePtr = (tSample *) Packet;
         for (i=0; i<SamplesPerPacket; i++) {
            SamplePtr[i] = Samples[tempHead];
            tempHead++;
            if (tempHead == MAX_NUM_SAMPLES) {
               tempHead = 0;
            }
         }
         status = call NetworkPacket.Send(Destination, Packet, 
                                          SamplesPerPacket*sizeof(tSample));
         if (status == SUCCESS) {
            Head = tempHead;
            atomic {
               NumSamples-= SamplesPerPacket;
            }
            NumPacketsSent++;
            if ((NumPacketsSent & 0x1) == 0xff) {
               sprintf(temp, "Sent %8X packets, Samples per packet %d\r\n", 
                    NumPacketsSent, SamplesPerPacket);
               debug_msg(temp);
            }
            NumOutstandingPackets++;
         } else {
            call NetworkPacket.ReleaseBuffer(Packet);
         }
      }
   }

   /*
    * SampleAcquired event
    */
   event result_t SampleAcquired(uint16 Tx, uint16 Ty, uint16 T) {
      if (Skipped < SkipSamples) {
         Skipped++;
         return SUCCESS;
      }

      Skipped = 0;
      SampleCount++;

      //sprintf(temp, "%d,%d,%d,%d\r\n", NumSamples, Head, Tail, NumOutstandingPackets);
      //debug_msg(temp);

      // Add to Queue if there is space
      if (NumSamples >= MAX_NUM_SAMPLES) {
         // drop it
         post SendSamples();
         return SUCCESS;
      }
      Samples[Tail].Tx = Tx;
      Samples[Tail].Ty = Ty;
      Samples[Tail].T = T;
      NumSamples++;
      Tail++;
      if (Tail == MAX_NUM_SAMPLES) {
         Tail = 0;
      }

#if 0
      sprintf(temp, "New Sample, NumSamples %d, Head %d, Tail %d\r\n", NumSamples, Head, Tail);
      debug_msg(temp);
#endif
      if (NumSamples >= SamplesPerPacket) {
         post SendSamples();
      }

      return SUCCESS;
   }

    event result_t RawSamples(uint8 *Data, uint16 NumBytes) {
       // Just send data as is
       uint8 i;
       uint8 *Packet;
       result_t status;

       Packet = call NetworkPacket.AllocateBuffer(NumBytes); 
       if (Packet == NULL) {
          return SUCCESS;
       }
       for (i=0; i<NumBytes; i++) {
          Packet[i] = Data[i];
       }
       status = call NetworkPacket.Send(Destination, Packet, NumBytes);
       if (status != SUCCESS) {
          call NetworkPacket.ReleaseBuffer(Packet);
       }
       return SUCCESS;
    }

    task void print_task() {
       sprintf(temp, "%d\r\n", MyTime);
       debug_msg(temp);
    } 
    /*
     * Start of Timer Interface
     */
    event result_t Timer.fired() {
       MyTime++;
       //sprintf(temp, "Sample Count %d, Time %d\r\n", SampleCount, MyTime);
       debug_msg(temp);
       SampleCount = 0;
    }

}  

