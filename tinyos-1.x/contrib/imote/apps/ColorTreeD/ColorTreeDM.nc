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
module ColorTreeDM {
    provides {
        interface StdControl;
        interface BluSH_AppI as app_collect;
        interface BluSH_AppI as app_autoON;
        interface BluSH_AppI as app_autoOFF;
        interface BluSH_AppI as app_lowpowerON;
        interface BluSH_AppI as app_lowpowerOFF;
        interface BluSH_AppI as app_numsensors;
        interface BluSH_AppI as app_help;
    }
    uses {
        interface StdControl as NetworkControl;
        interface NetworkCommand;
        interface NetworkPacket;
        interface Timer as AckTimer;
        interface NetworkLowPower;
        interface LowPower;
        command result_t NetworkWriteScanEnable(uint32 state);

#if (SEND_SAMPLE_TO_UART)
        interface HPLDMA;
        interface HPLUART;
#endif
        interface Leds8;
        interface Memory;
#if HARDWIRED_NETWORK
        interface NetworkHardwired;
#endif
    }
}
implementation {

/*
 * NUM_SAMPLES & SAMPLE_BYTES are used to reserve the buffer size, 
 * If sender sends less bytes, it is not an issue, however, the reverse won't work
 * NUM_FRAGMENTS is used for the ACK array size
 */
#define NUM_SAMPLES 3000
#define SAMPLE_BYTES 2
#define FRAGMENT_SIZE 100
#define NUM_FRAGMENTS 62 // (NUM_SAMPLES * SAMPLE_BYTES + hdr) / FRAGMENT_SIZE

/*
 * This defines the maximum number of NACKS that can be sent in a NACK packet
 */
#define MAX_NACK_SEGMENTS 50

/*
 * NACK_THRESHOLD is used to trigger sending NACKs if frag i + NACK_THRESHOLD is received
 * and fragment i hasn't been received
 */
#define NACK_THRESHOLD 	10       // 10 fragments

#define INVALID_BYTE_OFFSET 0xffff

/*
 * Timeout values:
 * ACK_CLOCK_TICK : main timer, 100 ms
 * INITIAL_COLLECTION_TIMEOUT : keep sending collection request until a data fragment is received
 *                              50 * 100 ms = 5 second timeout
 * TIME_BETWEEN_COLLECTIONS   : Time to wait between restarting the collection round (1 min)
 * ACTIVITY_TIMEOUT           : If we don't receive anything from sender for 1 second, we send NACK
 */ 
#define ACK_CLOCK_TICK 100	
#define INITIAL_COLLECTION_TIMEOUT 200	// 20 seconds
#define TIME_BETWEEN_COLLECTIONS   200  // 20 seconds
#define TIME_BETWEEN_SENSOR_CHECKS 50  // 5 seconds
#define COLLECT_COMMAND_TIMEOUT 5
#define ACK_RESPONSE_TIMEOUT 10
#define ACTIVITY_TIMEOUT 5
#define CONSECUTIVE_ACTIVITY_RETRIES 50  // Move to next mote if current mote unresponsive
#define OPPORTUNISTIC_NACK_INTERVAL 1    // 200 ms

#define SLEEP_DONE_TIMEOUT 1200
#define WAKEUP_TIMEOUT 1200

/*
 * For now, this is static, later will change it to dynamic
 */
#define NUM_SENSORS_PER_MOTE 1
#define TOTAL_SENSORS 1
    
/*
 * Request types
 */
#define TYPE_ACK 0			// Complete packet received by dest
#define TYPE_NACK 1   		// Nack a specific fragment (offset)
#define TYPE_START_COLLECTING 2	// start collecting samples, send when done

/*
 * States :
 */
#define STATE_IDLE 0
#define STATE_WAIT_DATA 1
#define STATE_RECEIVING 2
#define STATE_WAIT_ACK 3
#define STATE_WAIT_SEND 4	// optional, if we receive ACK before we're done sending
#define STATE_WAIT_TO_SLEEP 5
#define STATE_WAIT_TO_WAKEUP 6
#define STATE_SLEEPING 7
#define STATE_WAIT_FOR_INPUT 8
 
/*
 * Fragment Types
 */
#define FRAG_TYPE_DATA 0
#define FRAG_TYPE_REC_ACK 1

/*
 * Data types for the UART framing, to be decoded by windows app
 * allows inerleaving debug & data streams
 */
#define SENSOR_DATA_TYPE 0
#define DEBUG_INFO_TYPE 1


typedef struct tRequestPacketHeader {
   uint16 extra_info;
   uint8 type;
   uint8 sensor_id;
} tRequestPacketHeader;

typedef struct tSampleHeader {
   uint16 data_size;
   uint16 sensor_id;
} tSampleHeader;

typedef struct tFragHeader {
   uint16 offset;
   uint8 size;	// For now restrict fragment to 256 B.  TODO: If we need DM5, borrow some bits from type (combo field)
   uint8 type;  // Data, special responses
} tFragHeader;

typedef struct tTopology {
   uint32 slave;
   uint32 master;
} tTopology;

#define TOTAL_CONNECTIONS 20

/*
 * Debug modes
 */
#define DEBUG_BASIC 0x1
#define DEBUG_LOG 0x2
#define DEBUG_DETAIL 0x4
#define DEBUG_ERROR 0x8

#define MY_DEBUG_MODE 0x3

/*
 * FWD Declaration
 */
task void SendCollectRequest(); 


/*
 * Global Variables
 */
    extern tTOSBufferVar *TOSBuffer __attribute__ ((C)); 
    uint32 ThisNodeID;
    uint32 RelayNodeID;
    uint32 CurrentDestID;
    uint8 CurrentDestIndex;
    uint32 *DestIDs;
    uint16  NumDests;
    uint16 MaxReceivedOffset;
    uint16 MinUnReceivedOffset;
    uint16  CurrentSensorID;
    uint8 *Sample;
    uint8 *RequestPacket;
    tSampleHeader *SampleHdr;
    uint8  AckArray[NUM_FRAGMENTS];
    bool   ResendAck;
    bool   AckReceived;
    uint32 AckTime;
    uint32 RequestTime;
    uint32 ActivityTimeout;
    uint16 TotalFragments;
    int NumNacksSent;
    bool AllFragmentsReceived;
    uint16  NumReceivedFragments;
    uint16 UartNextByte;
    uint16 ActualBytesSent;
    uint32 IdleTimeout;
    uint8 State;
    uint16 NumRetries;
    uint32 FirstFragTime;
    uint32 LastFragTime;
    uint32 SendCollectTime;
    uint32 LastNackSent;
    uint32 NackSequenceNum;
#if HARDWIRED_NETWORK
    tTopology Connections[TOTAL_CONNECTIONS];
#endif
    uint8 TestCount;
    bool  DeadMote;
    bool  RoutingOn;
    bool  backed_off;
    bool  LowPowerInitialized;
    uint8  LowPowerMode;
    uint8  ManualCollector;

    #define DEBUG_LEVEL(mode) ((mode & MY_DEBUG_MODE)? DBG_USR1 : DBG_NONE) 
    
    command result_t StdControl.init() {

        call NetworkControl.init();
        call NetworkCommand.SetAppName("VibrationReceiver");
        call NetworkPacket.Initialize();
        TM_DisableDeepSleep(TM_DEEPSLEEP_APLICATION_ID_2);
        ThisNodeID = 0x85114;
        RelayNodeID = 0x85166;
        CurrentSensorID = 0;
        AckTime = 1;
        NackSequenceNum = 1;
        TM_DisableDeepSleep(TM_DEEPSLEEP_APLICATION_ID_2);

#if (FLEX_UART_DEBUG || SEND_SAMPLE_TO_UART)
        call HPLUART.init();	//115200
#endif

        NumDests = 0;
        DestIDs = NULL;
        IdleTimeout = AckTime + 50;	// wait five seconds before we check
        NumRetries = 0;
        TestCount = 0;
        DeadMote = false;
        RoutingOn = true;
        backed_off = false;
        LowPowerInitialized = false;

        /*
         * Operating modes, intialize to app.h defaults
         * can be changed dynamically
         */
        LowPowerMode = ENABLE_LOW_POWER;
        ManualCollector = MANUAL_COLLECTOR;

        if (ManualCollector) {
           State = STATE_WAIT_FOR_INPUT;
        } else {
           State = STATE_IDLE;
        }

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
        
        call NetworkControl.start();
        call NetworkCommand.GetMoteID(&ThisNodeID);
        call NetworkCommand.SetProperty(NETWORK_PROPERTY_DISPLAY);
        call NetworkCommand.SetProperty(NETWORK_PROPERTY_ACTIVE_ROUTING);
        call NetworkCommand.SetProperty(NETWORK_PROPERTY_CLUSTER_HEAD);

#if HARDWIRED_NETWORK
        for (i=0; i < TOTAL_CONNECTIONS; i++) {
           call NetworkHardwired.AddConnection(Connections[i].master, 
						Connections[i].slave);
        }
        call NetworkHardwired.start();
#endif

#if (FLEX_UART_DEBUG || SEND_SAMPLE_TO_UART)
        call HPLDMA.DMAGet(TOSBuffer->UARTRxBuffer,32);
#endif

        call AckTimer.start(TIMER_REPEAT, ACK_CLOCK_TICK);

        // membuf = call Memory.alloc(104, NUM_SAMPLES * SAMPLE_BYTES + sizeof(tSampleHeader));
        membuf = call Memory.alloc(NUM_SAMPLES * SAMPLE_BYTES + sizeof(tSampleHeader));
        if (membuf == NULL) {
           SampleHdr = NULL;
           Sample = NULL;
        } else {
           SampleHdr = (tSampleHeader *) membuf;
           Sample = (uint8 *) membuf;
        }

        trace(DEBUG_LEVEL(DEBUG_BASIC), "Started\r\n");
        return SUCCESS;
    }

    command result_t StdControl.stop() {
        call NetworkControl.stop();
        call NetworkPacket.ReleaseBuffer(RequestPacket);
        return SUCCESS;
    }

    result_t InitReceiveState() {
       uint8 i;
       for(i=0; i< NUM_FRAGMENTS; i++) {
          AckArray[i] = 0;
       }

       MaxReceivedOffset = INVALID_BYTE_OFFSET;
       MinUnReceivedOffset = 0;
       ResendAck = false;
       AckReceived = false;
       TotalFragments = 0;
       NumNacksSent = 0;
       AllFragmentsReceived = false;
       NumReceivedFragments = 0;
       UartNextByte = sizeof(tSampleHeader);
       return SUCCESS;
    }
  
    bool IsSampleComplete() {
       uint8 extra_bytes;
       uint8 num_fragments;
       uint8 i;
       if (AckArray[0] == 0) {
          return false;
       }
       num_fragments = SampleHdr->data_size / FRAGMENT_SIZE;
       extra_bytes = SampleHdr->data_size % FRAGMENT_SIZE;
       if (extra_bytes) {
          num_fragments++;
       }
       for(i=0; i < num_fragments; i++) {
          if (AckArray[i] == 0) {
             return false;
          }
       }
#if 1
       call Leds8.bitOff(4);
       call Leds8.bitOff(5);
       call Leds8.bitOn(6);
#endif
       trace(DEBUG_LEVEL(DEBUG_DETAIL),"Compl,size %d,frags %d\r\n", SampleHdr->data_size, num_fragments);
       return true;
   }

   bool UpdateMinUnReceivedOffset() {
       uint8 i;
       bool ret_val = false;
       for(i=0; i < NUM_FRAGMENTS; i++) {
          if (AckArray[i] == 0) {
             ret_val = true;
             break;
          }
       }
       MinUnReceivedOffset = i * FRAGMENT_SIZE;
       return ret_val;
   }

   uint8 GetNumNacks() {
       uint8 NumNacks = 0;
       uint8 i;
       for(i=0; i < NUM_FRAGMENTS; i++) {
          if (AckArray[i] == 0) {
             NumNacks++;
          }
       }
       return NumNacks;
   }

   uint8 FillNackArray(uint8 NumNackEntries, uint16 *NackArray) {
       uint8 NumNacks = 0;
       uint8 i;
       for(i=0; i < NUM_FRAGMENTS; i++) {
          if (NumNacks >= NumNackEntries) {
             return NumNacks;
          }
          if (AckArray[i] == 0) {
             NackArray[NumNacks] = i * FRAGMENT_SIZE;
             NumNacks++;
          }
       }
   }

    task void SendSampleToUart() {
#if SEND_SAMPLE_TO_UART
       uint8 i;
       for (i=0; i<32; i++) {
          TOSBuffer->UARTTxBuffer[i] = Sample[UartNextByte];
          UartNextByte++;
          if (UartNextByte >= SampleHdr->data_size) {
             i++;
#if 0
             call Leds8.bitOff(4);
             call Leds8.bitOn(5);
             call Leds8.bitOff(6);
#endif
             break;
          }
       }
       call HPLDMA.DMAPut(TOSBuffer->UARTTxBuffer,i);
       ActualBytesSent+= i;
#endif
    }

    /*
     * Hdr is 16 B, consisting of :
     * Magic Number : DEADBEAF  (4 B)
     * Data Type : SENSOR_DATA_TYPE (2B)
     * Frame Length : 2 B
     * Over the Air time : Time between receipt of 1st frag & last frag
     * Mote ID : (4 B)
     * SensorID : (2 B)
     */ 
    task void SendSampleHdrToUart() {
#if SEND_SAMPLE_TO_UART
       uint16 SampleDataLen; 
       uint32 TimeOverAir;

       // Magic Number
       TOSBuffer->UARTTxBuffer[0] = 0xEF;
       TOSBuffer->UARTTxBuffer[1] = 0xBE;
       TOSBuffer->UARTTxBuffer[2] = 0xAD;
       TOSBuffer->UARTTxBuffer[3] = 0xDE;

       // Uart Data type
       TOSBuffer->UARTTxBuffer[5] = 0;
       TOSBuffer->UARTTxBuffer[4] = SENSOR_DATA_TYPE;

       // Sample Length
       SampleDataLen = SampleHdr->data_size - sizeof(tSampleHeader);
       TOSBuffer->UARTTxBuffer[7] = (uint8) ((SampleDataLen >> 8) & 0xff);
       TOSBuffer->UARTTxBuffer[6] = (uint8) (SampleDataLen & 0xff);

       // Time for sending data over the air in ms
       TimeOverAir = (LastFragTime - FirstFragTime) * ACK_CLOCK_TICK;
       TOSBuffer->UARTTxBuffer[11] = (uint8) ((TimeOverAir >> 24) & 0xff);
       TOSBuffer->UARTTxBuffer[10] = (uint8) ((TimeOverAir >> 16) & 0xff);
       TOSBuffer->UARTTxBuffer[9] = (uint8) ((TimeOverAir >> 8) & 0xff);
       TOSBuffer->UARTTxBuffer[8] = (uint8) (TimeOverAir & 0xff);
       // Mote ID
       TOSBuffer->UARTTxBuffer[15] = (uint8) ((CurrentDestID >> 24) & 0xff);
       TOSBuffer->UARTTxBuffer[14] = (uint8) ((CurrentDestID >> 16) & 0xff);
       TOSBuffer->UARTTxBuffer[13] = (uint8) ((CurrentDestID >> 8) & 0xff);
       TOSBuffer->UARTTxBuffer[12] = (uint8) (CurrentDestID & 0xff);
       // Sensor ID
       TOSBuffer->UARTTxBuffer[17] = (uint8) ((CurrentSensorID >> 8) & 0xff);
       TOSBuffer->UARTTxBuffer[16] = (uint8) (CurrentSensorID & 0xff);

       call HPLDMA.DMAPut(TOSBuffer->UARTTxBuffer,18);
       ActualBytesSent+= 18;
#else
       // If not sending to Uart (DEBUG_MODE) , fake it
       UartNextByte = SampleHdr->data_size;
#endif
    }

    task void SendAck() {
       result_t status;
       tRequestPacketHeader *AckHdr;
       // uint8 *AckPacket = call NetworkPacket.AllocateBuffer(100, sizeof(tRequestPacketHeader));
       uint8 *AckPacket = call NetworkPacket.AllocateBuffer(sizeof(tRequestPacketHeader));
       if (AckPacket == NULL) {
           ResendAck = true;
           return;
       }

       AckHdr = (tRequestPacketHeader *) AckPacket;
       AckHdr->type = TYPE_ACK;
       AckHdr->sensor_id = CurrentSensorID;
       status = call NetworkPacket.Send(CurrentDestID, AckPacket, sizeof(tRequestPacketHeader));
       if (status == FAIL) {
          call NetworkPacket.ReleaseBuffer(AckPacket);
          ResendAck = true;
          trace(DEBUG_LEVEL(DEBUG_ERROR),"Send Failed %5X\r\n", CurrentDestID);
          return;
       }
       RequestTime = AckTime;
       ResendAck = false;
       trace(DEBUG_LEVEL(DEBUG_DETAIL),"SendAck %5X,f %d,l %d\r\n", CurrentDestID, FirstFragTime, LastFragTime);
    }

    task void SendNack() {
       result_t status;
       tRequestPacketHeader *NackHdr;
       uint16 fragment_index;
       uint8 *NackPacket;
       uint8 NumNacks;
       uint16 *NackArray;
       uint32 *SeqNum;

       NumNacks = GetNumNacks();
       if (NumNacks == 0) {
          return;
       }

       // NackPacket = call NetworkPacket.AllocateBuffer(101,  sizeof(tRequestPacketHeader) + (NumNacks * 2));
       NackPacket = call NetworkPacket.AllocateBuffer(sizeof(tRequestPacketHeader) + (NumNacks * 2) + 4);
       if (NackPacket == NULL) {
           // TODO : What do we do
           return;
       }

       NackHdr = (tRequestPacketHeader *) NackPacket;
       NackHdr->type = TYPE_NACK;
       NackHdr->sensor_id = CurrentSensorID;
       NackHdr->extra_info = NumNacks;

       // Fill in the sequence number for the NACK packet
       SeqNum = (uint32 *) &(NackPacket[sizeof(tRequestPacketHeader)]);
       *SeqNum = NackSequenceNum;

       // Fill in the Nack data
       NackArray = (uint16 *) &(NackPacket[sizeof(tRequestPacketHeader) + 4]);
       NumNacks = FillNackArray(NumNacks, NackArray);

       status = call NetworkPacket.Send(CurrentDestID, NackPacket, sizeof(tRequestPacketHeader) + (NumNacks * 2) + 4);
       if (status == FAIL) {
          // TODO : What do we need to do
          call NetworkPacket.ReleaseBuffer(NackPacket);
          trace(DEBUG_LEVEL(DEBUG_ERROR), "Send Failed %5X\r\n", CurrentDestID);
          return;
       }
       fragment_index = (MinUnReceivedOffset / FRAGMENT_SIZE);
       NumNacksSent++;
       LastNackSent = AckTime;
    }

    task void SendCollectRequest() {
       // Init state and send collection request
       uint8 *Packet;
       tRequestPacketHeader *Hdr; 
       result_t status;

       SendCollectTime = AckTime;
       // First of all check if we space for the sample
       if (Sample == NULL) {
          // Write debug info and exit
          trace(DEBUG_LEVEL(DEBUG_ERROR), "Can't allocate sample\r\n");
          return;
       }

       // Packet = call NetworkPacket.AllocateBuffer(102, sizeof(tRequestPacketHeader));
       Packet = call NetworkPacket.AllocateBuffer(sizeof(tRequestPacketHeader));
       InitReceiveState();
       RequestTime = AckTime;

       if (Packet == NULL) {
           // TODO : What do we do
           return;
       }
       Hdr = (tRequestPacketHeader *) Packet;
       Hdr->type = TYPE_START_COLLECTING;
       Hdr->sensor_id = CurrentSensorID;
       /*
        * Send the total number of sensors that we will be collecting 
        * For now, we assume the receiver has knowledge, later we will
        * be able to pull this info from the mote
        */
       Hdr->extra_info = NUM_SENSORS_PER_MOTE;
       status = call NetworkPacket.Send(CurrentDestID, Packet, sizeof(tRequestPacketHeader));
       if (status == FAIL) {
          // TODO : What do we need to do
          call NetworkPacket.ReleaseBuffer(Packet);
          trace(DEBUG_LEVEL(DEBUG_ERROR), "Send Failed %5X\r\n", CurrentDestID);
          return;
       }

       trace(DEBUG_LEVEL(DEBUG_DETAIL), "Sent Request %05X\r\n", CurrentDestID);
       
#if 0
       call Leds8.bitOff(4);
       call Leds8.bitOn(5);
       call Leds8.bitOn(6);
#endif
    }

    // Create the Dest array
    task void ProcessFirstSensor() {

       if (DestIDs != NULL) {
          // Error, free it and start again
          call Memory.free((char *)DestIDs);
          DestIDs = 0;
       }

       NumDests = call NetworkCommand.GetNumNodesSupportingProperty(NETWORK_PROPERTY_APP_ACCELEROMETER);
       if (NumDests < TOTAL_SENSORS) {
          // wait more time
          trace(DEBUG_LEVEL(DEBUG_DETAIL),"Found %d sensors, wait\n\r", NumDests);
          if (!RoutingOn) {
// leave active routing on for the receiver node
// VEH             call NetworkCommand.SetProperty(NETWORK_PROPERTY_ACTIVE_ROUTING);
             RoutingOn = true;
          }
          return;
       } else {
          if (RoutingOn) {
             // Turn off routing, found all nodes
// VEH             call NetworkCommand.UnsetProperty(NETWORK_PROPERTY_ACTIVE_ROUTING);
             RoutingOn = false;
          }
       }

       /*
        * Back off one more time, to ensure that the network had a chance
        * to stablize (property exchanged is done
        */
       if (!backed_off) {
          backed_off = true;
          trace(DEBUG_LEVEL(DEBUG_BASIC), "Found all sensors,Starting Collection, Time %d\n\r", AckTime);
          return;
       } else {
          backed_off = false;
       }

       // DestIDs = (uint32 *) call Memory.alloc(103, NumDests * sizeof(uint32));
       DestIDs = (uint32 *) call Memory.alloc(NumDests * sizeof(uint32));
       if (DestIDs == NULL) {
          trace(DEBUG_LEVEL(DEBUG_ERROR),"No memory DestIDs\n\r");
          return;
       }

       trace(DEBUG_LEVEL(DEBUG_DETAIL),"Found all %d sensors\n\r",NumDests);
       
       call NetworkCommand.GetNodesSupportingProperty(NETWORK_PROPERTY_APP_ACCELEROMETER, 
                                                      NumDests, DestIDs);
       CurrentDestIndex = 0;
       CurrentSensorID = 0;
       CurrentDestID = DestIDs[0];
       State = STATE_WAIT_DATA;
       RequestTime = AckTime;	// init request time
       post SendCollectRequest();
          
    }

    task void ProcessNextSensor() {
       CurrentSensorID++;
       if ((CurrentSensorID >= NUM_SENSORS_PER_MOTE) || DeadMote) {
          /*
           * TODO: for now assume hardcoded num sensors per mote, 
           * later, poll mote for this info
           */
          CurrentDestIndex++;
          CurrentSensorID = 0;
          DeadMote = false;
          if (CurrentDestIndex >= NumDests) {
             // Done with all Destinations
             if (LowPowerMode && !ManualCollector) {
                /*
                 * If in low power and auto mode, when we finish a 
                 * collection we put Nodes in sleep
                 */
        
                // Set time if we don't get low power event back
                IdleTimeout = AckTime + SLEEP_DONE_TIMEOUT;  
                State = STATE_WAIT_TO_SLEEP;
                call NetworkLowPower.NetworkEnterLowPower(
				TIME_BETWEEN_COLLECTIONS*ACK_CLOCK_TICK);
             } else if (ManualCollector) {
                   /*
                    * Manual collector, go back to waiting for input
                    */

                State = STATE_WAIT_FOR_INPUT;
             } else {
                IdleTimeout = AckTime + TIME_BETWEEN_COLLECTIONS;
                State = STATE_IDLE;
             }

             trace(DEBUG_LEVEL(DEBUG_LOG), "Collected All Nodes, Time %d\r\n", AckTime);
             call Memory.free((char *)DestIDs);
             DestIDs = 0;
             return;
          }
       }

       // Found Destination index, set it up
       CurrentDestID = DestIDs[CurrentDestIndex];
       State = STATE_WAIT_DATA;
       RequestTime = AckTime;	// init request time
       post SendCollectRequest();
    }

    event result_t NetworkPacket.Receive(uint32 Source, uint8 *Data, uint16 Length) {
       uint16 i;
       tFragHeader *FragHdr;
       tSampleHeader *Hdr;
       uint8 *FragData;
       uint8 fragment_index;
       uint16 *sensor_id_ptr;

       /*
        * First of all, check if this is coming from the sensor of interest
        * Drop everything else
        * TODO : Send Reset command
        */
       if (Source != CurrentDestID) {
          return SUCCESS;
       }

       // TODO: Should we set a limit for total start to finish time?
       NumRetries = 0;	// received something, reset retry count

       FragHdr = (tFragHeader *)Data;
       FragData = &(Data[sizeof(tFragHeader)]);
       
       /*
        * check type, Ack vs Data
        */
       if (FragHdr->type == FRAG_TYPE_REC_ACK) {
          if (State != STATE_WAIT_ACK)  {
             // Only track ACKs if we are in the ACK state.
             return SUCCESS;
          }

          sensor_id_ptr = (uint16 *) FragData;
          if (CurrentSensorID != *sensor_id_ptr) {
             // old packet, ignore
             trace(DEBUG_LEVEL(DEBUG_ERROR),"Invalid sensor %d (expected %d) at node %05X\r\n", CurrentSensorID, *sensor_id_ptr, CurrentDestID);
             return SUCCESS;
          }

          trace(DEBUG_LEVEL(DEBUG_LOG),"got:Sensor %d,Mote %x,OverAir %d,Sent %d,Nacks %d,Time %d\r\n", 
                  CurrentSensorID, Source, 
                  (LastFragTime - FirstFragTime) * ACK_CLOCK_TICK,
                  FragHdr->offset, NumNacksSent, AckTime); 
          
          /*
           * Current Sensor ID, Sender received the ACK, 
           * check if we are done sending data, if so, trigger next sensor
           */
          AckReceived = true;
          State = STATE_WAIT_SEND;
          if (UartNextByte >= SampleHdr->data_size) {
             trace(DEBUG_LEVEL(DEBUG_DETAIL),"Done with Sensor %05X\r\n",CurrentDestID);
             post ProcessNextSensor();
          } else {
             trace(DEBUG_LEVEL(DEBUG_DETAIL),"Sending Sensor %05X\r\n",CurrentDestID);
          }
          return SUCCESS;
       }

       if (FragHdr->type != FRAG_TYPE_DATA) {
          // unsupported type
          trace(DEBUG_LEVEL(DEBUG_ERROR),"Invalid type \r\n");
          return SUCCESS;
       }

       /*
        * Sensor Data Fragment
        * Should be in RECEIVING state, or WAITING_STATE
        */
       if ((State != STATE_RECEIVING) && (State != STATE_WAIT_DATA)) {
          return SUCCESS;
       }

       State = STATE_RECEIVING;

       fragment_index = (FragHdr->offset / FRAGMENT_SIZE);
       if (fragment_index >= NUM_FRAGMENTS) {
          // Invalid fragment
          return FAIL;
       }

       NackSequenceNum++;

       // Reset activity timeout
       ActivityTimeout = AckTime + ACTIVITY_TIMEOUT;

       if (AckArray[fragment_index] == 1) {
          // got it already, do nothing
          return SUCCESS;
       }

       if (NumReceivedFragments == 0) {
          FirstFragTime = AckTime;
       }

       NumReceivedFragments++;
       if (fragment_index == 0) {
          Hdr = (tSampleHeader *) &FragData[0];
          TotalFragments = Hdr->data_size / FRAGMENT_SIZE;
          if (Hdr->data_size % FRAGMENT_SIZE) {
             TotalFragments++;
          }
       } 

       // New packet, copy to the sample buffer and update ack state
       for (i = 0; i <  FragHdr->size; i++) {
          Sample[FragHdr->offset + i] = FragData[i];
       }
       AckArray[fragment_index] = 1;

       trace(DEBUG_LEVEL(DEBUG_DETAIL),"Rec frag %d of %d,\r\n",fragment_index, NumReceivedFragments);
       
       if (IsSampleComplete()) {
          LastFragTime = AckTime;
          post SendAck();
          AllFragmentsReceived = true;
          State = STATE_WAIT_ACK;
          RequestTime = AckTime;
          // UartNextByte = sizeof(tSampleHeader);	// Done in InitRecieve
          ActualBytesSent = 0;
#if 0	// For testing only
          for (i=0; i < SampleHdr->data_size; i++) {
             Sample[i+sizeof(tSampleHeader)] = i & 0xff;
          }
#endif
          post SendSampleHdrToUart();	// Send sample header (12 bytes), followed by data
          return SUCCESS;
       }

       // Update the state, and check if we need to send a NACK
       if ((FragHdr->offset > MaxReceivedOffset) || 
           (MaxReceivedOffset == INVALID_BYTE_OFFSET)) {
          MaxReceivedOffset = FragHdr->offset;
       }

       // If we received the "lowest" fragment, update MinUnReceivedOffset
       if (MinUnReceivedOffset == FragHdr->offset) {
          UpdateMinUnReceivedOffset();
       }
    }

    event result_t NetworkPacket.SendDone(char *data) {
        call NetworkPacket.ReleaseBuffer(data);
        return SUCCESS;
    }

/*
 * Start of NetworkCommand interface.
 */


  event result_t NetworkCommand.CommandResult( uint32 Command, uint32 value) {
      bool test;
      switch (Command) {
         case COMMAND_NEW_NODE_CONNECTION: // new node found
             test = call NetworkCommand.IsPropertySupported(value, 
                                             NETWORK_PROPERTY_APP_ACCELEROMETER); 

             trace(DEBUG_LEVEL(DEBUG_BASIC),"Connected %5X, %d Time %d\n\r", value, test, AckTime);
             TestCount++;
#if 0
            if (TestCount & 1) {
               call Leds8.bitOff(4);
               call Leds8.bitOn(5);
               call Leds8.bitOff(6);
            } else {
               call Leds8.bitOff(4);
               call Leds8.bitOff(5);
               call Leds8.bitOn(6);
            }
#endif
            break;

         case COMMAND_NODE_DISCONNECTION: // new node found
            trace(DEBUG_LEVEL(DEBUG_BASIC),"Disconnected %5X Time %d\n\r", value, AckTime);
            break;
      }
          
      return SUCCESS;
  }

/*
 * Start of Timer Interface
 */
  event result_t AckTimer.fired() {

    uint16 AvailableMemory;

    AckTime++;

    if ((AckTime & 0xff) == 0xff) {
       AvailableMemory = call Memory.available();
       trace(DEBUG_LEVEL(DEBUG_DETAIL),"Memory=%d,Time=%d\r\n", AvailableMemory, AckTime);
    }

    if (!LowPowerInitialized) {
       call LowPower.init(20000, 25000);
       LowPowerInitialized = true;
    }

    // First check retries
    if (NumRetries > CONSECUTIVE_ACTIVITY_RETRIES) {
       // TODO : move to next sensor or next mote?
       DeadMote = true;
       post ProcessNextSensor();
       NumRetries = 0;
       trace(DEBUG_LEVEL(DEBUG_LOG),"Skipping Mote %x Time %d\r\n", CurrentDestID, AckTime);
       return SUCCESS;
    }

    switch (State) {
    case STATE_IDLE:
       // Check if the collection timeout has passed
       if (AckTime > IdleTimeout) {
          post ProcessFirstSensor();
          IdleTimeout = AckTime + TIME_BETWEEN_SENSOR_CHECKS;
       }
       return SUCCESS;

    case STATE_WAIT_DATA:
       // Sent request, haven't received data yet, check if we need to resend request
       if (AckTime > (RequestTime + COLLECT_COMMAND_TIMEOUT)) {
          NumRetries++;
          post SendCollectRequest();
       }
       return SUCCESS;

    case STATE_RECEIVING:
       // Receiving data from sensor

#if 0
       // Check if we need to send any NACK
       if ((MaxReceivedOffset != INVALID_BYTE_OFFSET) && 
           (AckTime > (LastNackSent +  OPPORTUNISTIC_NACK_INTERVAL)) &&
           ((MaxReceivedOffset - MinUnReceivedOffset) > 
             (NACK_THRESHOLD * FRAGMENT_SIZE))) {
          post SendNack();
       }
#endif

       // Check activity timeout
       if (AckTime > ActivityTimeout) {
          NumRetries++;
          post SendNack();
       }

       return SUCCESS;

    case STATE_WAIT_ACK:
       if (ResendAck) {
          // Couldn't send ACK before
          post SendAck();
          return SUCCESS;
       }
       if (AckTime > (RequestTime + ACK_RESPONSE_TIMEOUT)) {
          NumRetries++;
          post SendAck();
       }
       return SUCCESS;

    case STATE_SLEEPING:
       if (AckTime > IdleTimeout) {
          // Start waking up network
          call NetworkLowPower.NetworkExitLowPower();
          IdleTimeout = AckTime + WAKEUP_TIMEOUT;
          State = STATE_WAIT_TO_WAKEUP;
          trace(DEBUG_LEVEL(DEBUG_LOG), "going to state %d,Time=%d\r\n", State, AckTime);
       }
       return SUCCESS;
       
    case STATE_WAIT_TO_SLEEP:
       // Check if we never get the Done event for entering low power
       if (AckTime > IdleTimeout) {
          // Go to Idle
          IdleTimeout = AckTime + TIME_BETWEEN_COLLECTIONS;
          State = STATE_SLEEPING;
          trace(DEBUG_LEVEL(DEBUG_LOG),"Timedout:going to state %d,Time=%d\r\n", State, AckTime);
       }
       return SUCCESS;

    case STATE_WAIT_TO_WAKEUP:
       if (AckTime > IdleTimeout) {
          IdleTimeout = AckTime + TIME_BETWEEN_COLLECTIONS;
          if (ManualCollector) {
             State = STATE_WAIT_FOR_INPUT;
          } else {
             State = STATE_IDLE;
          }
          trace(DEBUG_LEVEL(DEBUG_LOG), "Timed out: going to state %d,Time=%d\r\n", State, AckTime);
       }
       return SUCCESS;
     }
  }

#if (FLEX_UART_DEBUG || SEND_SAMPLE_TO_UART)

  /*
   * HPLUART interface
   */ 
  async event result_t HPLUART.get(uint8_t data) {
     return SUCCESS;
  }

  async event result_t HPLUART.putDone() {
     return SUCCESS;
  }

  /*
   * HPLDMA
   */

  async event uint8* HPLDMA.DMAGetDone(uint8 *data, uint16 Bytes) {
    
      return TOSBuffer->UARTRxBuffer;
  }

  async event result_t HPLDMA.DMAPutDone(uint8 *data) {
#if SEND_SAMPLE_TO_UART
    if (AllFragmentsReceived) {
       if (UartNextByte < SampleHdr->data_size) {
          post SendSampleToUart();
       }  else {
          // Done sending, check if we need to trigger next sensor
          if (AckReceived) {
#if 1
             call Leds8.bitOff(4);
             call Leds8.bitOn(5);
             call Leds8.bitOff(6);
#endif

             post ProcessNextSensor();
          }
       }
    }
#endif

    return SUCCESS;
  }
#endif

/*
 * NetworkLowPower Interface
 */
  event result_t NetworkLowPower.NetworkEnterLowPowerDone() { 
     // Move on to next state, done with this 
     if (State == STATE_WAIT_TO_SLEEP) {
        IdleTimeout = AckTime + TIME_BETWEEN_COLLECTIONS;
        State = STATE_SLEEPING;
        trace(DEBUG_LEVEL(DEBUG_LOG), "going to state %d,Time=%d\r\n", State, AckTime);
     }
     return SUCCESS; 
  }

  event result_t NetworkLowPower.NetworkExitLowPowerDone() { 
     // Move on to next state, done with this 
     if (State == STATE_WAIT_TO_WAKEUP) {
        IdleTimeout = AckTime + 2;
        if (ManualCollector) {
           State = STATE_WAIT_FOR_INPUT;
        } else {
           State = STATE_IDLE;
        }
        trace(DEBUG_LEVEL(DEBUG_LOG), "going to state %d,Time=%d\r\n", State, AckTime);
     }
     return SUCCESS; 
  }

  event result_t NetworkLowPower.NetworkInitLowPowerDone() { 
     return SUCCESS;
  }

  command BluSH_result_t app_collect.getName(char* buff, uint8_t len ){
      strcpy( buff, "collect" );
      return BLUSH_SUCCESS_DONE;
  }
  
  command BluSH_result_t app_collect.callApp( char* cmdBuff, uint8_t cmdLen,
                                       char* resBuff, uint8_t resLen ){
      if (State == STATE_WAIT_FOR_INPUT) {
          IdleTimeout = AckTime + 2;
          State = STATE_IDLE;
          strcpy(resBuff,"Collection Requested\r\n");
      } 
      else {
          strcpy(resBuff, "Not in wait state\r\n");
      }
      
      return BLUSH_SUCCESS_DONE;
  }
  
  command BluSH_result_t app_autoON.getName(char* buff, uint8_t len ){
      strcpy( buff, "a" );
      return BLUSH_SUCCESS_DONE;
  }
  
  command BluSH_result_t app_autoON.callApp( char* cmdBuff, uint8_t cmdLen,
                                       char* resBuff, uint8_t resLen ){
      /*
       * Go to automatic mode, no manual collection
       */
      ManualCollector = 0;
      /*
       * need to check if we are in wait state, if so
       * force to idle to get out of wait 
       */
      strcpy(resBuff, "Switch to Auto\r\n");
      if (State == STATE_WAIT_FOR_INPUT) {
          IdleTimeout = AckTime + 2;
          State = STATE_IDLE;
      }
      
      return BLUSH_SUCCESS_DONE;
  }
  
  
  command BluSH_result_t app_autoOFF.getName(char* buff, uint8_t len ){
      strcpy( buff, "A" );
      return BLUSH_SUCCESS_DONE;
  }
  
  command BluSH_result_t app_autoOFF.callApp( char* cmdBuff, uint8_t cmdLen,
                                              char* resBuff, uint8_t resLen ){
      /*
       * Go to Manual mode
       */
      strcpy(resBuff, "Switch to Manual\r\n");
      ManualCollector = 1;
      if (State == STATE_IDLE) {
          State = STATE_WAIT_FOR_INPUT;
      }
      return BLUSH_SUCCESS_DONE;
  }

  command BluSH_result_t app_lowpowerON.getName(char* buff, uint8_t len ){
      strcpy( buff, "p" );
      return BLUSH_SUCCESS_DONE;
  }
  
  command BluSH_result_t app_lowpowerON.callApp( char* cmdBuff, uint8_t cmdLen,
                                              char* resBuff, uint8_t resLen ){
      /*
       * Go to Manual mode
       */
      strcpy(resBuff, "Enable Low Power\r\n");
      LowPowerMode = 1;
      
      return BLUSH_SUCCESS_DONE;
  }

  command BluSH_result_t app_lowpowerOFF.getName(char* buff, uint8_t len ){
      strcpy( buff, "P" );
      return BLUSH_SUCCESS_DONE;
  }
  
  command BluSH_result_t app_lowpowerOFF.callApp( char* cmdBuff, uint8_t cmdLen,
                                              char* resBuff, uint8_t resLen ){
      /*
       * Go to Manual mode
       */
      strcpy(resBuff, "Disable Low Power\r\n");
      LowPowerMode = 0;

      return BLUSH_SUCCESS_DONE;
  }

  command BluSH_result_t app_numsensors.getName(char* buff, uint8_t len ){
      strcpy( buff, "numsensors" );
      return BLUSH_SUCCESS_DONE;
  }
  
  command BluSH_result_t app_numsensors.callApp( char* cmdBuff, uint8_t cmdLen,
                                              char* resBuff, uint8_t resLen ){
      /*
       * status : Number of found sensors and current state
       */
      uint8 num_sensors;
      num_sensors = call NetworkCommand.GetNumNodesSupportingProperty(NETWORK_PROPERTY_APP_ACCELEROMETER);
      sprintf(resBuff, "Status: Num sensors %d, State %d\r\n", num_sensors, State);
      
      return BLUSH_SUCCESS_DONE;
  }

  command BluSH_result_t app_help.getName(char* buff, uint8_t len ){
      strcpy( buff, "h" );
      return BLUSH_SUCCESS_DONE;
  }
  
  command BluSH_result_t app_help.callApp( char* cmdBuff, uint8_t cmdLen,
                                              char* resBuff, uint8_t resLen ){
      strcpy(resBuff,"App commands : \r\n");
      strcat(resBuff,"n = Number of Sensors found \r\n");
      strcat(resBuff,"c = Collect \r\n");
      strcat(resBuff,"a = Switch to automatic collections \r\n");
      strcat(resBuff,"A = Switch to Manual collection \r\n");
      strcat(resBuff,"p = Enable Low Power in Auto mode \r\n"); 
      strcat(resBuff,"P = Disable Low Power in Auto Mode\r\n");
      return BLUSH_SUCCESS_DONE;
  }
    
  /*
 * Low Power
 */
   event result_t LowPower.EnterLowPowerComplete() {
      return SUCCESS;
   }

   event result_t LowPower.PowerModeChange(bool IsLowPower) {
      return SUCCESS;
   }

}
