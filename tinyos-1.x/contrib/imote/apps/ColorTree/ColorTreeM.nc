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
module ColorTreeM {
    provides {
        interface StdControl;
    }
    uses {
#if SENSOR_CONNECTED
        interface Sensor;
        interface StdControl as SensorControl;
#endif
        interface StdControl as NetworkControl;
        interface NetworkCommand;
        interface NetworkPacket;
#if HARDWIRED_NETWORK
        interface NetworkHardwired;
#endif
        interface Timer as SendTimer;
        interface Memory;
#if (ENABLE_LOW_POWER)
        interface LowPower;
#endif
    }
}
implementation {

#define NUM_SAMPLES 3000
#define SAMPLE_BYTES 2
#define INVALID_BYTE_OFFSET 0xffff
#define FRAGMENT_SIZE 100
#define SEND_CLOCK_TICK 40
#define MAX_OUTSTANDING_SENDS 4

/*
 * This defines the maximum number of NACKs that can be sent in a nack packet
 */
#define MAX_NACK_SEGMENTS 50
    
#define TYPE_ACK 0			// Complete packet received by dest
#define TYPE_NACK 1   		// Nack a specific fragment (offset)
#define TYPE_START_COLLECTING 2	// start collecting samples, send when done

/*
 * Sensor Timeout
 */
#define SENSOR_TIMEOUT 1500  // 30 seconds timeout (SEND_CLOCK_TICK * SENSOR_TIMEOUT)
#define SENSOR_TURN_ON_TIMEOUT 50  // 2 seconds to turn on board
#define CONSECUTIVE_SEND_FAILURES_LIMIT 250	// 10 seconds

/*
 * Frag types
 */
#define FRAG_TYPE_DATA 0
#define FRAG_TYPE_REC_ACK 1

/*
 * PreSelect the next sensor to meet the timing requirement 
 */
#define PRESELECT_SENSOR 1

typedef struct tRequestPacketHeader {
   uint16 extra_info;	// Used only in Nack packets, to send number of nacks
   uint8 type;
   uint8 sensor_id;
} tRequestPacketHeader;

typedef struct tSampleHeader {
   uint16 data_size;
   uint16 sensor_id;
} tSampleHeader;

typedef struct tFragHeader {
   uint16 offset;
   uint8 size;	
   uint8 type;
} tFragHeader;

typedef struct tTopology {
   uint32 slave;
   uint32 master;
} tTopology;

#define TOTAL_CONNECTIONS 20

    uint32 ThisNodeID;
    uint32 Destination;
    uint32 RelayNodeID;
    uint16 NextByte;
    uint8 RetryByteIndex;
    uint32 RetrySeqNum;
    uint8  DuplicateNacks;
    uint16 NumRetryBytes;
    uint16 RetryBytes[MAX_NACK_SEGMENTS];
    bool CollectingSamples;	// true while collecting 
    bool SendingSamples;	// true while sending
    bool ResendAck;
    uint8 *Sample;
    tSampleHeader *SampleHdr;
    uint16 NumBytes;
    uint16 CurrentSensorID;
    uint32 MyTime;
    uint32 SensorTimeout;
    uint8  iteration;
    bool   SensorOn;
    bool   WaitForSensor;
    uint16 NumSensors;
    uint16 NumFragmentsSent;	// For logging purposes
#if HARDWIRED_NETWORK
    tTopology Connections[TOTAL_CONNECTIONS];
#endif
    uint16 ConsecutiveSendFailures;

    int OutstandingSends;
    bool InitializedLowPower;

    char temp[32];

    void debug_msg (char *str) {

#if DEBUG_ON
       trace(DBG_USR1, str);
#endif
     }

    command result_t StdControl.init() {
        uint8 i;
#if SENSOR_CONNECTED
        call SensorControl.init();
        call Sensor.SetSampleWidth(1, 2);
        SensorOn = false;
        WaitForSensor = false;
#endif
        call NetworkControl.init();
        call NetworkCommand.SetAppName("FabSensor");
        call NetworkPacket.Initialize();

        Destination = 0x85114;
        CollectingSamples = false;
        SendingSamples = false;
        ResendAck = false;
        MyTime = 1;
        iteration = 0;
        OutstandingSends = 0;
        ConsecutiveSendFailures = 0;
        RetrySeqNum = 0;
        DuplicateNacks = 0;

#if ENABLE_LOW_POWER
        InitializedLowPower = false;
#endif

#if HARDWIRED_NETWORK
        call NetworkHardwired.init();
        for (i = 0; i < TOTAL_CONNECTIONS; i++) {
           Connections[i].slave = 0;
           Connections[i].master = 0;
        }

        Connections[0].slave = 0x85105;
        Connections[0].master = 0x85183;
        Connections[1].slave = 0x85097;
        Connections[1].master = 0x85183;
        Connections[2].slave = 0x85133;
        Connections[2].master = 0x85183;
        Connections[3].slave = 0x85136;
        Connections[3].master = 0x85183;

        Connections[4].slave = 0x85155;
        Connections[4].master = 0x85105;
        Connections[5].slave = 0x85071;
        Connections[5].master = 0x85105;
        Connections[6].slave = 0x85027;
        Connections[6].master = 0x85105;

        Connections[8].slave = 0x85033;
        Connections[8].master = 0x85097;
        Connections[9].slave = 0x85175;
        Connections[9].master = 0x85097;
        Connections[10].slave = 0x85031;
        Connections[10].master = 0x85097;

        Connections[12].slave = 0x85166;
        Connections[12].master = 0x85133;
        Connections[13].slave = 0x85011;
        Connections[13].master = 0x85133;
        Connections[14].slave = 0x85067;
        Connections[14].master = 0x85133;

#endif

        return SUCCESS;
    }

    command result_t StdControl.start() {
        char *membuf;
        uint8 i;
        bool Master = false;

        call NetworkControl.start();
        call NetworkCommand.GetMoteID(&ThisNodeID);
        call NetworkCommand.SetProperty(NETWORK_PROPERTY_APP_ACCELEROMETER);

#if HARDWIRED_NETWORK
        call NetworkCommand.EnablePageScan();
        for (i=0; i < TOTAL_CONNECTIONS; i++) {
           call NetworkHardwired.AddConnection(Connections[i].master, 
						Connections[i].slave);
        }
        call NetworkHardwired.start();
#endif

        call SendTimer.start(TIMER_REPEAT, SEND_CLOCK_TICK);

        // Allocate space for the sample buffer
        // membuf = call Memory.alloc(100, NUM_SAMPLES * SAMPLE_BYTES + sizeof(tSampleHeader));
        membuf = call Memory.alloc(NUM_SAMPLES * SAMPLE_BYTES + sizeof(tSampleHeader));
        if (membuf == NULL) {
           SampleHdr = NULL;
           Sample = NULL;
        } else {
           SampleHdr = (tSampleHeader *) &(membuf[0]);
           Sample = (uint8 *) &(membuf[0]);
        }

        sprintf(temp, "Started Senor %x\r\n",ThisNodeID);
        debug_msg(temp);

        return SUCCESS;
    }

    command result_t StdControl.stop() {
        call NetworkControl.stop();
        return SUCCESS;
    }

#if SENSOR_CONNECTED
   task void CollectSamples() {
      call Sensor.AcquireSamples((uint8) CurrentSensorID, 
                                 &(Sample[sizeof(tSampleHeader)]), NUM_SAMPLES);
      SensorTimeout = MyTime + SENSOR_TIMEOUT;
      CollectingSamples = true;
      WaitForSensor = false;
   }
#endif

    /*
     * SendAckRecv()
     *    Sends confirmation that the ACK was received
     */
    task void SendAckRecv() {
        tFragHeader *FragHdr;
        uint16 *FragData;
        result_t status;
        uint8 *AckPacket;

        // AckPacket = call NetworkPacket.AllocateBuffer(101, sizeof(tFragHeader) + 2);
        AckPacket = call NetworkPacket.AllocateBuffer(sizeof(tFragHeader) + 2);
        if (AckPacket == NULL) {
            sprintf(temp, "can't allocate ACK packet %d\r\n", OutstandingSends);
            debug_msg(temp);
            return;
        }

        /*
         * Fill in the fragment header
         * Overload the offset field for num fragments sent over air
         */
        FragHdr = (tFragHeader *) AckPacket;
        FragHdr->offset = NumFragmentsSent;
        FragHdr->size = 2;
        FragHdr->type = FRAG_TYPE_REC_ACK;
        
        // fragment buffer was allocated already, just fill in
        FragData = (uint16 *) (&AckPacket[sizeof(tFragHeader)]);
        *FragData = CurrentSensorID;

        status = call NetworkPacket.Send(Destination, AckPacket, 2 + sizeof(tFragHeader));

        if (status != SUCCESS) {
           call NetworkPacket.ReleaseBuffer(AckPacket);
           sprintf(temp, "can't send ack %x\r\n", Destination);
           debug_msg(temp);
           ResendAck = true;
        } else {
           OutstandingSends++;
           ResendAck = false;
        }
    }

    /*
     * SendData()
     *    Send a fragment of Sensor Data
     */
    task void SendData() {
       
        uint16 offset;
        uint16 i;
        bool retry = false;
        uint16 frag_size; 
        result_t status;
        tFragHeader *FragHdr;
        uint8 *FragData;
        uint8 *Fragment;

        if (SendingSamples == false) {
           return;
        }
        
        /*
         * Check if we reached the maximum number of outstanding
         * packets to the lower layer.
         */
        if (OutstandingSends > MAX_OUTSTANDING_SENDS) {
           ConsecutiveSendFailures++;
           debug_msg("Reached max outstanding\r\n");
           return;
        }

        // Give priority to retry bytes
        if (RetryByteIndex < NumRetryBytes) {
           offset = RetryBytes[RetryByteIndex];
           retry = true;
        } else {
           if (NextByte < NumBytes) {
              // Send next fragment
              offset = NextByte;
           } else {
              return;	// Nothing to send
           }
        }

        frag_size = NumBytes - offset;
        if (frag_size > FRAGMENT_SIZE) {
           frag_size = FRAGMENT_SIZE;
        }

        // Fragment = call NetworkPacket.AllocateBuffer(102, FRAGMENT_SIZE + sizeof(tFragHeader));
        Fragment = call NetworkPacket.AllocateBuffer(FRAGMENT_SIZE + sizeof(tFragHeader));
        if (Fragment == NULL) {
            sprintf(temp, "can't allocate frag %d\r\n", OutstandingSends);
            debug_msg(temp);
            ConsecutiveSendFailures++;
            return;
        }

        // Fill in the fragment header
        FragHdr = (tFragHeader *) Fragment;
        FragHdr->offset = offset;
        FragHdr->size = (uint8) frag_size;
        FragHdr->type = FRAG_TYPE_DATA;
        
        // fragment buffer was allocated already, just fill in
        FragData = &Fragment[sizeof(tFragHeader)];
        for (i=0; i < frag_size; i++) {
            FragData[i] = Sample[offset+i];
        }

        status = call NetworkPacket.Send(Destination, Fragment, frag_size+sizeof(tFragHeader));

        if (status == SUCCESS) {
           ConsecutiveSendFailures = 0;
           NumFragmentsSent++;
           OutstandingSends++;
           if (retry) {
              RetryByteIndex++;
           } else {
              NextByte += frag_size;
           }
        }  else {
           call NetworkPacket.ReleaseBuffer(Fragment);
           sprintf(temp, "can't send frag %x\r\n", Destination);
           debug_msg(temp);
           ConsecutiveSendFailures++;
        }
    }

#if SENSOR_CONNECTED
    event result_t Sensor.SamplesAcquired(uint8 SensorID,
                                          uint8 *Buffer,
                                          uint16 NumSamples) {
        uint16 i;
        uint16 *DataPtr;


        if (!CollectingSamples) {
           debug_msg("duplicate samples acquired");
           return FAIL;
        }

#if PRESELECT_SENSOR
        if (SensorID >= (NumSensors - 1)) {
           call Sensor.SelectSensor(0);
        } else {
           call Sensor.SelectSensor(SensorID+1);
        }
#endif

        SendingSamples = true;
        NumFragmentsSent = 0;
        CollectingSamples = false;
        NumBytes = NumSamples * SAMPLE_BYTES + sizeof(tSampleHeader);

        /*
         * Adjust sensor data
         */
        DataPtr = (uint16 *) &(Sample[sizeof(tSampleHeader)]);
        for(i=0; i<NumSamples ; i++) {
           *DataPtr = *DataPtr << 1;
           DataPtr++; 
        }

        // Fill in the header
        SampleHdr->data_size = NumBytes;
        SampleHdr->sensor_id = SensorID;
        CurrentSensorID = SensorID;

        NextByte = 0;
        RetryByteIndex = 0;
        NumRetryBytes = 0;
        RetrySeqNum = 0;

        post SendData();

#if 0
        TM_ResetPio(4);
        TM_ResetPio(5);
        TM_SetPio(6);
#endif

        return SUCCESS;
    }
#endif

    event result_t NetworkPacket.Receive(uint32 Source, uint8 *Data, uint16 Length) {

        uint16 i;
        tRequestPacketHeader *ReqPacket;
        uint16 *NackData;
        uint32 *SeqNum;
        ReqPacket = (tRequestPacketHeader *) Data;

        if (Sample == NULL) {
           return FAIL;
        }

        switch (ReqPacket->type) {
           case TYPE_ACK :
              // Complete Packet Received by dest, update state
              SendingSamples = false;
              post SendAckRecv();
              sprintf(temp, "ACK from %x\r\n", Source);
              debug_msg(temp);
#if SENSOR_CONNECTED
              if (CurrentSensorID == (NumSensors - 1)) {
                 // turn off board when we receive last sensor ack
                 call SensorControl.stop();
                 SensorOn = false;
              }
#endif
              // Reset time to avoid wrap around
              MyTime = 1;
              break;
           
           case TYPE_NACK :
              // Resend requested offset
              NackData = (uint16 *) &(Data[sizeof(tRequestPacketHeader) + 4]);
              SeqNum = (uint32 *) &(Data[sizeof(tRequestPacketHeader)]);
              if (*SeqNum == RetrySeqNum) {
                 sprintf(temp, "Duplicate NACK Time %d \r\n",MyTime);
                 debug_msg(temp);
                 if (RetryByteIndex < NumRetryBytes) {
                    // Currently processing the NACK, skip this duplicate NACK
                    return SUCCESS;
                 }
                
                 // Not processing a NACK
                 if ((NumRetryBytes > 2) && (DuplicateNacks < 5)) {
                    // Duplicate NACK packet, skip it
                    DuplicateNacks++;
                    return SUCCESS;
                 }
              }
              NumRetryBytes = ReqPacket->extra_info;
              RetryByteIndex = 0;
              RetrySeqNum = *SeqNum;
              DuplicateNacks = 0;

              for(i=0; i<NumRetryBytes; i++) {
                 RetryBytes[i] = NackData[i];
              }
              post SendData();
              sprintf(temp, "NACK from %x outstanding %x\r\n", Source,
	      OutstandingSends);
              debug_msg(temp);
              break;

           case TYPE_START_COLLECTING :
              // Drop request if we are currently collecting samples
              if (!CollectingSamples) {
                 CurrentSensorID = ReqPacket->sensor_id;
                 NumSensors = ReqPacket->extra_info;
                 if (SendingSamples) {
                    SendingSamples = false; // force a synch with receiver
                    sprintf(temp, "Col req in send,sensor %x\r\n", CurrentSensorID);
                 } else {
                    sprintf(temp, "Col req Sensor %x\r\n", CurrentSensorID);
                 }
                 debug_msg(temp);
                 ConsecutiveSendFailures = 0;
                 Destination = Source;	// Send the packets to whoever requested them (No Hardcoding)
                 // Reset the timer, so we don't wrap around
#if SENSOR_CONNECTED
#if 0
                 TM_ResetPio(4);
                 TM_ResetPio(5);
                 TM_SetPio(6);
#endif
                 if (SensorOn) {
                    post CollectSamples();
                 } else {
                    if (!WaitForSensor) {
                       WaitForSensor = true;    
                       SensorTimeout = MyTime + SENSOR_TURN_ON_TIMEOUT;
                       call SensorControl.start();
                       call Sensor.SelectSensor(0);
                    }
                 }
                    
#else
                 iteration++;
                 CollectingSamples = false;
                 SendingSamples = true;
                 NumFragmentsSent = 0;
                 NumBytes = NUM_SAMPLES * SAMPLE_BYTES + sizeof(tSampleHeader);

                 // Fill in the header
                 SampleHdr->data_size = NumBytes;
                 CurrentSensorID = ReqPacket->sensor_id;
                 SampleHdr->sensor_id = CurrentSensorID;

                 NextByte = 0;
                 RetryByteIndex = 0;
                 NumRetryBytes = 0;
                 RetrySeqNum = 0;
                 for(i=sizeof(tSampleHeader); i < SampleHdr->data_size; i++) {
                   Sample[i] = iteration;
                 }

                 post SendData();
		
#endif
              } else {
                 sprintf(temp, "already collecting\r\n");
                 debug_msg(temp);
	      }
              break;

        }
        return SUCCESS;
    }

    event result_t NetworkPacket.SendDone(char *data) {
        call NetworkPacket.ReleaseBuffer(data);
        OutstandingSends--;
        return SUCCESS;
    }

/*
 * Start of NetworkCommand interface.
 */


  event result_t NetworkCommand.CommandResult( uint32 Command, uint32 value) {
          
      switch (Command) {
         case COMMAND_NEW_NODE_CONNECTION:
#if 0
               TM_ResetPio(4);
               TM_SetPio(5);
               TM_ResetPio(6);
#endif
            break;
      }
               
      return SUCCESS;
  }

/*
 * Start of Timer Interface
 */
  event result_t SendTimer.fired() {

        uint16 AvailableMemory;
        MyTime++;

#if 0
        if ((MyTime & 0xff) == 0xff) {
           AvailableMemory = call Memory.available();
           sprintf(temp, "Memory=%d,Time=%d\r\n", AvailableMemory, MyTime);
           debug_msg(temp);
        }
#endif
        if (!InitializedLowPower) {
           call LowPower.init(20000, 25000);
           InitializedLowPower = true;
        }

#if SENSOR_CONNECTED
        if (CollectingSamples) {
           /*
            * Check sensor timeout, this is to prevent us from getting stuck in this state
            * If data never comes back from PLD
            */
           if (MyTime > SensorTimeout) {
              // Reset state
              // call SensorControl.init();
              // call Sensor.SetSampleWidth(1, 2);
              CollectingSamples = false;
              return SUCCESS;
           }
        } else if (WaitForSensor) {
           if (MyTime > SensorTimeout) {
              SensorOn = true;
              post CollectSamples();
              return SUCCESS;
           }
        }
#endif

        if (!SendingSamples) {
           if (ResendAck) {
              post SendAckRecv();
           }
           return SUCCESS;
        }

        if (ConsecutiveSendFailures >= CONSECUTIVE_SEND_FAILURES_LIMIT) {
           // Give up and reset state
           SendingSamples = false;
           return SUCCESS;
        }

        if ((RetryByteIndex < NumRetryBytes) || (NextByte < NumBytes)) {
           // More stuff to process
           post SendData();
        }

        return SUCCESS;
  }

/*
 * Low Power
 */
   event result_t LowPower.EnterLowPowerComplete () {
      return SUCCESS;
   }

   event result_t LowPower.PowerModeChange (bool IsLowPowerMode) {
      return SUCCESS;
   }
}

