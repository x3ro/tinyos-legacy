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
module AccelerometerDisplayM {
    provides interface StdControl;
    uses {
        interface StdControl as NetworkControl;
        interface NetworkCommand;
        interface NetworkPacket;
        interface Timer as MyTimer;
        interface Memory;
#if SEND_SAMPLE_TO_UART
        interface HPLUART;
        interface HPLDMA;
#endif
        interface Leds8;
#if HARDWIRED_NETWORK
        interface NetworkHardwired;
#endif
    }
}
implementation {

// FWD Dec
result_t ReceivedDataFromSensor(uint32 MoteID);


#define MY_CLOCK_TICK 100	
#define COLLECT_COMMAND_TIMEOUT 5

/*
 * Commands
 */
#define CMD_START 0	// Start sending data, extra info = # samples / packet
#define CMD_STOP  1	// Stop sending data

/*
 * SENSOR TYPES
 */
#define PH_SENSOR 1
#define PRESSURE_SENSOR 2
#define ACCELEROMETER_SENSOR 3

typedef struct tRequestPacketHeader {
   uint8 cmd;
   uint8 info1;
   uint8 info2;
   uint8 info3;
} tRequestPacketHeader;

typedef struct tTopology {
   uint32 slave;
   uint32 master;
} tTopology;

typedef struct tSensorInfo {
   uint32 Addr;
   bool   ReceivedData;
} tSensorInfo;

typedef struct tSample {
   uint16 Tx;
   uint16 Ty;
   uint16 T;
} tSample;

#define TOTAL_CONNECTIONS 20
#define MAX_SENSORS 4
#define NUM_SAMPLES_PER_PACKET 1
#define NUM_SKIPPED_SAMPLES 9
#define UART_HEADER_SIZE 14	// DEADBEEF, MOTE ID, #SAMPLES, Sensor Type, extra info
#define UART_BUFFER_SIZE (UART_HEADER_SIZE + (NUM_SAMPLES_PER_PACKET * sizeof(tSample)))
#define MAX_BUFFERS 5

/*
 * This define will force the receiver to wait until all sensors connect
 * before it requests data from any of them
 * This is just to allow the connections to occur before we bombard the
 * network with data
 * After NETWORK_TIMEOUT we timeout and allow data requests to start
 */
#define TOTAL_SENSORS 1
#define NETWORK_TIMEOUT 600

/*
 * Global Variables
 */
    extern tTOSBufferVar *TOSBuffer __attribute__ ((C)); 
    uint32 ThisNodeID;
    uint32 MyTime;
    uint8  NumSensors;
    tSensorInfo Sensors[MAX_SENSORS];
    uint8  Head, Tail, NumUsedBuffers;
    uint8  NumUartBuffers;
    uint8 *UartBuffers[MAX_BUFFERS];
    uint16 UartBufferSizes[MAX_BUFFERS];
    bool   SendingToUart;
    uint8  LastCollectRequest;
    char   temp[200];
    uint8  ConnectedSensors;
    uint32 ReceivedSamples;
    uint32 SampleCount;
    uint8  SecondCounter;
#if HARDWIRED_NETWORK
    tTopology Connections[TOTAL_CONNECTIONS];
    uint8  NumConnections;
#endif

void debug_msg (char *str) {
#if DEBUG_ON
       trace(DBG_USR1, str);
#endif
}


    command result_t StdControl.init() {
        uint8 i;
        call NetworkControl.init();
        call NetworkCommand.SetAppName("AccelerometerDisplay");
        call NetworkPacket.Initialize();
        MyTime = 1;
        NumSensors = 0;
        LastCollectRequest = 0;
        Head = Tail = NumUsedBuffers = 0;
        ConnectedSensors = 0;

        for(i=0; i<MAX_SENSORS; i++) {
           Sensors[i].Addr = 0;
        }

#if SEND_SAMPLE_TO_UART
        // call HPLDMAUart.init(eTM_B115200);	//115200
         call HPLUART.init();	//115200
#endif

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
        SendingToUart = false;
        SampleCount = 0;
        SecondCounter = 0;
        return SUCCESS;
    }

    command result_t StdControl.start() {
        char *membuf;
        uint8 i;

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

#if SEND_SAMPLE_TO_UART
        call HPLDMA.DMAGet(TOSBuffer->UARTRxBuffer,32);
#endif

        call MyTimer.start(TIMER_REPEAT, MY_CLOCK_TICK);

        NumUartBuffers = 0;
        for (i=0; i<MAX_BUFFERS; i++) {
           UartBuffers[i] = call Memory.alloc(UART_BUFFER_SIZE);
           if (UartBuffers[i] == NULL) {
              break;
           }
           NumUartBuffers++;
        }

        return SUCCESS;
    }

    command result_t StdControl.stop() {
        call NetworkControl.stop();
        return SUCCESS;
    }

    /*
     * Hdr is 10 B, consisting of :
     * Magic Number : DEADBEAF  (4 B)
     * Mote ID : (4 B)
     * Length in bytes : (2 B)
     */ 
    void FillUartBuffer(uint8 *UartBuffer, uint32 MoteID, uint16 Length, 
                        uint8 *Samples) {

       uint8 i;
       uint16 SensorType = ACCELEROMETER_SENSOR;

       // Magic Number
       UartBuffer[0] = 0xEF;
       UartBuffer[1] = 0xBE;
       UartBuffer[2] = 0xAD;
       UartBuffer[3] = 0xDE;

       // Mote ID
       UartBuffer[7] = (uint8) ((MoteID >> 24) & 0xff);
       UartBuffer[6] = (uint8) ((MoteID >> 16) & 0xff);
       UartBuffer[5] = (uint8) ((MoteID >> 8) & 0xff);
       UartBuffer[4] = (uint8) (MoteID & 0xff);

       // Sensor Type
       UartBuffer[9] = (uint8) ((SensorType >> 8) & 0xff);
       UartBuffer[8] = (uint8) (SensorType & 0xff);

       // Length
       UartBuffer[11] = (uint8) ((Length >> 8) & 0xff);
       UartBuffer[10] = (uint8) (Length & 0xff);

       // Extra Info
       UartBuffer[13] = 0;
       UartBuffer[12] = 0;

       // Sample data is 2 bytes each, need to flip endianess
       for(i=0; i<Length; i=i+2) {
          // Each sample has 3 16 bit values, Tx, Ty, T
          UartBuffer[14+i] = Samples[i+1];
          UartBuffer[14+i+1] = Samples[i];
       } 
    }

    task void SendBufferToUart() {
#if SEND_SAMPLE_TO_UART
       if ((NumUsedBuffers == 0) || (SendingToUart)) {
          return;
       }
       SendingToUart = true;
       call HPLDMA.DMAPut(UartBuffers[Head], UartBufferSizes[Head]);
#endif
    }

    void SendCollectRequest(uint32 MoteID) {
       uint8 *Packet;
       result_t status;
       tRequestPacketHeader *Hdr;

       Packet = call NetworkPacket.AllocateBuffer(sizeof(tRequestPacketHeader));
       if (Packet == NULL) {
           // TODO : What do we do
           return;
       }

       Hdr = (tRequestPacketHeader *) Packet;
       Hdr->cmd = CMD_START;
       Hdr->info1 = NUM_SAMPLES_PER_PACKET;
       Hdr->info2 = NUM_SKIPPED_SAMPLES;
       status = call NetworkPacket.Send(MoteID, Packet, 
                                        sizeof(tRequestPacketHeader));
       if (status == SUCCESS) {
          sprintf(temp, "Sent Collect Request to %5x\r\n", MoteID);
          debug_msg(temp);
       } else {
          // TODO : What do we need to do
          call NetworkPacket.ReleaseBuffer(Packet);
          sprintf(temp, "Failed Collect Request to %5x\r\n", MoteID);
          debug_msg(temp);
       }
    }

    event result_t NetworkPacket.Receive(uint32 Source, uint8 *Data, 
                                         uint16 Length) {
       uint8 i;
       uint16 max_len;
       char test[200];

       //sprintf(temp, "Received from %5x, size = %d\r\n", Source, Length);
       //debug_msg(temp);
       SampleCount = SampleCount + (Length/6);

       /*
        * First of all, check if this data is coming from a mote that we 
        * requested data from
        */
       if (ReceivedDataFromSensor(Source) == FAIL) {
          // unknown sensor, drop data
          return SUCCESS;
       }

#if RAW_SAMPLES
       // just dump out to the screen the raw samples
       temp[0] = 0;
       for(i=0; i<Length; i++) {
          sprintf(temp, "%s,%x",temp, Data[i]);
       }
       sprintf(temp, "%s\r\n",temp);
       debug_msg(temp);
       return SUCCESS;
#endif
       // Each sample is 6 bytes
       max_len = NUM_SAMPLES_PER_PACKET * sizeof(tSample);
       if (Length > max_len) {
          Length = max_len;
       }
       
#if SEND_SAMPLE_TO_UART
       // Find empty UART buffer, and fill in data
       if (NumUsedBuffers < NumUartBuffers) {
          FillUartBuffer(UartBuffers[Tail], Source, Length, Data); 
          UartBufferSizes[Tail] = Length + UART_HEADER_SIZE;
          NumUsedBuffers++;
          Tail++;
          if (Tail == NumUartBuffers) {
             Tail = 0;
          }
          post SendBufferToUart();
       }
#else
#if 1
       FillUartBuffer(test, Source, Length, Data); 
       temp[0] = 0;
       for(i=0; i<Length; i++) {
          sprintf(temp, "%s,%x",temp, test[i+10]);
       }
       debug_msg(temp);
#endif
#endif

       return SUCCESS;
    }
       
    event result_t NetworkPacket.SendDone(char *data) {
        call NetworkPacket.ReleaseBuffer(data);
        return SUCCESS;
    }

    result_t ReceivedDataFromSensor(uint32 MoteID) {
       uint8 i;
       for(i=0; i<MAX_SENSORS; i++) {
          if (Sensors[i].Addr == MoteID) {
             Sensors[i].ReceivedData = true;
             return SUCCESS;
          }
       }
       return FAIL;
    }

    result_t RemoveSensor(uint32 MoteID) {
       uint8 i;
       for(i=0; i<MAX_SENSORS; i++) {
          if (Sensors[i].Addr == MoteID) {
             NumSensors--;
             Sensors[i].Addr = 0;
             return SUCCESS;
          }
       }
       return FAIL;
    }

    result_t AddSensor(uint32 MoteID) {
       uint8 i;

       if (NumSensors > MAX_SENSORS) {
          return FAIL;
       }

       for(i=0; i<MAX_SENSORS; i++) {
          if (Sensors[i].Addr == MoteID) {
             return FAIL;
          }
       }

       for(i=0; i<MAX_SENSORS; i++) {
          if (Sensors[i].Addr == 0) {
             // Found empty slot
             Sensors[i].Addr = MoteID;
             Sensors[i].ReceivedData = false;
             NumSensors++;
             return SUCCESS;
          }
       }
       return FAIL;
    }
/*
 * Start of NetworkCommand interface.
 */

  event result_t NetworkCommand.CommandResult( uint32 Command, uint32 value) {
     bool test;
     switch (Command) {
        case COMMAND_NEW_NODE_CONNECTION: // new node found
           if (call NetworkCommand.IsPropertySupported(value, 
                        NETWORK_PROPERTY_APP_STREAMING_ACCEL) == true) {

              if (AddSensor(value) == SUCCESS) {
                 sprintf(temp, "Connected %5x, Added\r\n", value);
                 debug_msg(temp);
                 ConnectedSensors++;
              } else {
                 sprintf(temp, "Connected %5x, Already Added\r\n", value);
                 debug_msg(temp);
              }
           }
           break;

        case COMMAND_NODE_DISCONNECTION: // new node found
           if (RemoveSensor(value) == SUCCESS) {
              sprintf(temp, "Removed %5x\r\n", value);
              debug_msg(temp);
              ConnectedSensors--;
           }
           break;
     }
          
     return SUCCESS;
  }

/*
 * Start of Timer Interface
 */
  event result_t MyTimer.fired() {

     uint8 i;
     uint8 sensor;
     MyTime++;
     SecondCounter++;
     if (SecondCounter == 9) {
        sprintf(temp, "Samples %d, Time %d\r\n", SampleCount, MyTime);
        debug_msg(temp);
        SecondCounter = 0;
        SampleCount = 0;
     }

     if (NumUsedBuffers > 0) {
        post SendBufferToUart();
     }
     
     if ((ConnectedSensors < TOTAL_SENSORS) && (MyTime < NETWORK_TIMEOUT)) {
        return SUCCESS;
     }

     // Check if any of the receivers haven't started sending data
     sensor = LastCollectRequest;	// start where we left off
     for(i=0; i<MAX_SENSORS; i++) {
        sensor++;
        if (sensor >= MAX_SENSORS) {
           sensor = 0;
        }
        
        if ((Sensors[sensor].Addr != 0) && (Sensors[sensor].ReceivedData == false)) {
           SendCollectRequest(Sensors[sensor].Addr);
           LastCollectRequest = sensor;
           return SUCCESS;
        }
     }
     return SUCCESS;
  }

/*
 * HPLDMAUart
 */
#if SEND_SAMPLE_TO_UART

  async event uint8* HPLDMA.DMAGetDone(uint8 *data, uint16 Bytes) {
    
      return TOSBuffer->UARTRxBuffer;
  }

  async event result_t HPLDMA.DMAPutDone(uint8 *data) {

     atomic {
        SendingToUart = false;
        // Remove entry at head of queue
        Head++;
        if (Head == NumUartBuffers) {
           Head = 0;
        }
        NumUsedBuffers--;

        // Check if more buffers to send
     }
     post SendBufferToUart();
     return SUCCESS;
  }

  async event result_t HPLUART.get(uint8 data){
      return SUCCESS;
  }
  async event result_t HPLUART.putDone(){
      return SUCCESS;
  }
#endif

  

}
