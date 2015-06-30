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
module GenericDisplayM {
    provides {
        interface StdControl;
#if DEBUG_ON
        interface BluSH_AppI as app_collect;
        interface BluSH_AppI as app_help;
#endif
    }

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
#if HARDWIRED_NETWORK
        interface NetworkHardwired;
#endif
        command result_t TOSToIMoteAddr(uint16 TOSAddr, uint32 *Imote_Addr);

        interface VarRecv;
        interface StdControl as ReliableTransportControl;

    }
}
implementation {

// FWD Dec
result_t ReceivedDataFromSensor(uint32 MoteID);
uint16 GetSensorType(uint32 MoteID);
void DoneSendingBuffer();


#define MY_CLOCK_TICK 100	
#define COLLECT_COMMAND_TIMEOUT 5

/*
 * Commands
 */
#define CMD_START 0	// Start sending data, extra info = # samples / packet
#define CMD_STOP  1	// Stop sending data
#define CMD_COLLECT 2   // take picture, start sending data
#define CMD_SEND_NEXT 3 // Send next chunk in picture
#define CMD_DONE 4      // Got complete picture
#define RESP_ACK 5      // ACK for COLLECT & SEND_NEXT

/*
 * SENSOR TYPES
 */
#define INVALID_SENSOR 0
#define PH_SENSOR 1
#define PRESSURE_SENSOR 2
#define ACCELEROMETER_SENSOR 3
#define CAMERA_SENSOR 4
#define TEMP_SENSOR 5

/*
 * States
 */
#define IDLE_STATE 0
#define SEND_COLLECT_STATE 1
#define SEND_NEXT_STATE 2

#define CMD_RETRY_LIMIT 20	// 10 second max
#define CMD_RETRY_TIMEOUT 5	// retry twice a second

#define END_OF_PIC 0xffff
#define FIRST_SEG 0x1111
#define MID_SEG 0x0

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
   uint16 Type;
   bool   ReceivedData;
} tSensorInfo;

typedef struct tAccelSample {
   uint16 Tx;
   uint16 Ty;
   uint16 T;
} tAccelSample;

typedef struct tTempSample {
   uint32 Temp;
   uint32 Humidity;
} tTempSample;

#define TOTAL_CONNECTIONS 20
#define MAX_SENSORS 4
#define NUM_SAMPLES_PER_PACKET 1
#define NUM_SKIPPED_SAMPLES 9
#define UART_HEADER_SIZE 14	
#define UART_BUFFER_SIZE (UART_HEADER_SIZE + (NUM_SAMPLES_PER_PACKET * sizeof(tAccelSample)))
#define MAX_BUFFERS 10 
#define TEMP_DATA_DELAY 5	// a sample every 5 seconds

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
    uint32 CurrentHandle;
    uint32 CurrentCameraSensor;
    uint32 ReceiveReqTime;
    uint32 ReceiveDoneTime;
    bool   BulkRecvInProgress;
    uint8  *CameraBuffer;
    uint16 CameraBufferSize;
    uint16 PaddedSize;
    bool   CameraBufferPending;
    bool   SendingCameraBuffer;
    uint16 SegmentFlag;
    uint32 CmdSentTime;
    bool   CaptureInProgress;
    uint8  RetryCount;
    uint8  State;
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
        call ReliableTransportControl.init();
        MyTime = 1;
        NumSensors = 0;
        LastCollectRequest = 0;
        Head = Tail = NumUsedBuffers = 0;
        ConnectedSensors = 0;
        CurrentHandle = 1;
        CurrentCameraSensor = 0;
        BulkRecvInProgress = false;
        CameraBufferPending = false;
        SegmentFlag = 0;
        CaptureInProgress = false;
        RetryCount = 0;

        for(i=0; i<MAX_SENSORS; i++) {
           Sensors[i].Addr = 0;
        }

#if SEND_SAMPLE_TO_UART
         //call HPLUART.setRate(eTM_B57600);	//57600
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
        SendingCameraBuffer = false;
        return SUCCESS;
    }

    command result_t StdControl.start() {
        uint8 i;

        TM_DisableDeepSleep(TM_DEEPSLEEP_APLICATION_ID_2);
        call NetworkControl.start();
        call NetworkCommand.GetMoteID(&ThisNodeID);
        call ReliableTransportControl.start();
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
        call ReliableTransportControl.stop();
        return SUCCESS;
    }

    /*
     * Hdr is 10 B, consisting of :
     * Magic Number : DEADBEAF  (4 B)
     * Mote ID : (4 B)
     * Length in bytes : (2 B)
     */ 
    void FillUartBuffer(uint8 *UartBuffer, uint32 MoteID, uint16 Length, 
                        uint16 Type, uint16 ExtraInfo, uint8 *Samples) {

       uint8 i;

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
       UartBuffer[9] = (uint8) ((Type >> 8) & 0xff);
       UartBuffer[8] = (uint8) (Type & 0xff);

       // Length
       UartBuffer[11] = (uint8) ((Length >> 8) & 0xff);
       UartBuffer[10] = (uint8) (Length & 0xff);

       // Extra info
       UartBuffer[13] = (uint8) ((ExtraInfo >> 8) & 0xff);
       UartBuffer[12] = (uint8) (ExtraInfo & 0xff);

       if (Samples == NULL) {
          // just fill in header
          return;
       }

       // Sample data is 2 bytes each, need to flip endianess
       for(i=0; i<Length; i=i+2) {
          // Each sample has 3 16 bit values, Tx, Ty, T
          UartBuffer[14+i] = Samples[i+1];
          UartBuffer[14+i+1] = Samples[i];
       } 
    }

    task void SendBufferToUart() {
#if 0
       sprintf(temp, "SendBuffToUart %d %d %d\r\n", SendingToUart, CameraBufferPending, NumUsedBuffers);
       debug_msg(temp);
#endif
#if SEND_SAMPLE_TO_UART
       if (SendingToUart) {
          return;
       }
       if (CameraBufferPending) {
          SendingToUart = true;
          SendingCameraBuffer = true;
          call HPLDMA.DMAPut(CameraBuffer, PaddedSize);
          debug_msg("Send cam buf\r\n");
       } else if (NumUsedBuffers > 0) {
          SendingToUart = true;
          call HPLDMA.DMAPut(UartBuffers[Head], UartBufferSizes[Head]);
          // debug_msg("Send regular buf\r\n");
       } 
#else
       SendingCameraBuffer = true;
       DoneSendingBuffer();
#endif
    }

    void StartStreaming(uint32 MoteID) {
       uint8 *Packet;
       result_t status;
       tRequestPacketHeader *Hdr;
       uint16 SensorType;

       Packet = call NetworkPacket.AllocateBuffer(sizeof(tRequestPacketHeader));
       if (Packet == NULL) {
           // TODO : What do we do
           return;
       }

       Hdr = (tRequestPacketHeader *) Packet;
       Hdr->cmd = CMD_START;
       SensorType = GetSensorType(MoteID);
       if (SensorType == ACCELEROMETER_SENSOR) {
          Hdr->info1 = NUM_SAMPLES_PER_PACKET;
          Hdr->info2 = NUM_SKIPPED_SAMPLES;
       } else {
          Hdr->info1 = TEMP_DATA_DELAY;
       }
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

    void SendCmd(uint32 MoteID, uint8 cmd) {
       uint8 *Packet;
       result_t status;
       tRequestPacketHeader *Hdr;

       Packet = call NetworkPacket.AllocateBuffer(sizeof(tRequestPacketHeader));
       if (Packet == NULL) {
           // TODO : What do we do
           return;
       }

       RetryCount++;
       Hdr = (tRequestPacketHeader *) Packet;
       Hdr->cmd = cmd;
       Hdr->info1 = 0;
       Hdr->info2 = 0;
       status = call NetworkPacket.Send(MoteID, Packet, 
                                        sizeof(tRequestPacketHeader));
       if (status == SUCCESS) {
          sprintf(temp, "Sent cmd %d to %5x\r\n", cmd, MoteID);
          debug_msg(temp);
       } else {
          // TODO : What do we need to do
          call NetworkPacket.ReleaseBuffer(Packet);
          sprintf(temp, "Failed sending cmd to %5x\r\n", MoteID);
          debug_msg(temp);
       }
       CmdSentTime = MyTime;
    }

    event result_t NetworkPacket.Receive(uint32 Source, uint8 *Data, 
                                         uint16 Length) {
       uint8 i;
       tRequestPacketHeader *Hdr;
       uint16 max_len;
       char test[200];
       uint16 SensorType;
       tTempSample *TempSample;

       //sprintf(temp, "Received from %5x, size = %d\r\n", Source, Length);
       //debug_msg(temp);

       /*
        * First of all, check if this data is coming from a mote that we 
        * requested data from
        */
       if (ReceivedDataFromSensor(Source) == FAIL) {
          // unknown sensor, drop data
          return SUCCESS;
       }
     
       /*
        * If coming from Camera sensor, look at header
        */
       SensorType = GetSensorType(Source);
       if (SensorType == CAMERA_SENSOR) {
          Hdr = (tRequestPacketHeader *) Data;
          if (Hdr->cmd == RESP_ACK) {
             State = IDLE_STATE;	// don't resend cmd
             RetryCount = 0;
          }
          return SUCCESS;
       }
       
       /*
        * TODO : treat temp sensor differently until we change
        * the windows app to handle temp data
        */
       if (SensorType == TEMP_SENSOR) {
          // for now, just print out to debug terminal
          TempSample = (tTempSample *) Data; 
          sprintf(temp, "Mote %5X, Temperature %02dF, Humidity %02d %% \r\n",
                  Source, TempSample->Temp, TempSample->Humidity);
          debug_msg(temp);
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
       max_len = NUM_SAMPLES_PER_PACKET * sizeof(tAccelSample);
       if (Length > max_len) {
          Length = max_len;
       }
       
#if SEND_SAMPLE_TO_UART
       // Find empty UART buffer, and fill in data
       if (NumUsedBuffers < NumUartBuffers) {
          FillUartBuffer(UartBuffers[Tail], Source, Length, 
                         ACCELEROMETER_SENSOR, 0, Data); 
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
       FillUartBuffer(test, Source, Length, ACCELEROMETER_SENSOR, 0, Data); 
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

    uint32 GetFirstSensor(uint16 Type) {
       uint8 i;
       for(i=0; i<MAX_SENSORS; i++) {
          if (Sensors[i].Type == Type) {
             return Sensors[i].Addr;
          }
       }
       return 0;
    }

    uint16 GetSensorType(uint32 MoteID) {
       uint8 i;
       for(i=0; i<MAX_SENSORS; i++) {
          if (Sensors[i].Addr == MoteID) {
             return Sensors[i].Type;
          }
       }
       return INVALID_SENSOR;
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

    result_t AddSensor(uint32 MoteID, uint16 Type) {
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
             Sensors[i].Type = Type;
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
     switch (Command) {
        case COMMAND_NEW_NODE_CONNECTION: // new node found
           if (call NetworkCommand.IsPropertySupported(value, 
                        NETWORK_PROPERTY_APP_STREAMING_ACCEL) == true) {

              if (AddSensor(value, ACCELEROMETER_SENSOR) == SUCCESS) {
                 sprintf(temp, "Connected %5x, Added\r\n", value);
                 debug_msg(temp);
                 ConnectedSensors++;
              } else {
                 sprintf(temp, "Connected %5x, Already Added\r\n", value);
                 debug_msg(temp);
              }
           } else if (call NetworkCommand.IsPropertySupported(value, 
                        NETWORK_PROPERTY_APP_CAMERA) == true) {

              if (AddSensor(value, CAMERA_SENSOR) == SUCCESS) {
                 sprintf(temp, "Connected %5x, Added\r\n", value);
                 debug_msg(temp);
                 ConnectedSensors++;
              } else {
                 sprintf(temp, "Connected %5x, Already Added\r\n", value);
                 debug_msg(temp);
              }
           } else if (call NetworkCommand.IsPropertySupported(value, 
                        NETWORK_PROPERTY_APP_SENSIRION) == true) {

              if (AddSensor(value, TEMP_SENSOR) == SUCCESS) {
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
 * Reliable Data Transport
 */
   /*
    * VarRecv interface
    */
   event result_t VarRecv.recvReq(uint16_t SrcAddr, uint16_t NumBytes, 
                                  uint8_t TransactionID) {
      debug_msg("Conn Req\r\n");
      if (BulkRecvInProgress) {
         sprintf(temp, "reject req from %x, multiple reqs\r\n", SrcAddr);
         debug_msg(temp);
         call VarRecv.rejectRecv(TransactionID);
         return SUCCESS;
      }

      /*
       * The first 2 bytes contain a flag to indicate end of picture
       */
      CameraBufferSize = NumBytes + UART_HEADER_SIZE - 2;

      // Pad buffer sent to uart to 2 bytes increment
      PaddedSize = CameraBufferSize;
      if (CameraBufferSize & 1) {
         PaddedSize++;
      }

      CameraBuffer = call Memory.alloc(PaddedSize);
      if (CameraBuffer == NULL) {
         sprintf(temp, "reject req from %x, no memory\r\n", SrcAddr);
         debug_msg(temp);
         call VarRecv.rejectRecv(TransactionID);
         return SUCCESS;
      }

      // Accept the request
      State = IDLE_STATE;	// received data, don't resend cmd
      RetryCount = 0;
      BulkRecvInProgress = true;
      CurrentHandle++;
      call TOSToIMoteAddr(SrcAddr, &CurrentCameraSensor);
      call VarRecv.acceptRecv((void *)CurrentHandle, TransactionID);
      sprintf(temp, "Recv Request from %x, %x \r\n", SrcAddr, CurrentCameraSensor);
      debug_msg(temp);
      ReceiveReqTime = MyTime;
      return SUCCESS;
   }

   event result_t VarRecv.putSegReq(void *Handle, uint16_t MsgOffset, 
                                    uint8_t *SegBuf, uint8_t SegSize){
      uint8 i;
      uint16 *temp_ptr;
      if (MsgOffset == 0) {
         // first segment, check if the end of picture flag is set
         temp_ptr = (uint16 *) SegBuf;
         SegmentFlag = *temp_ptr;
         sprintf(temp, "Seg flag %d\r\n", SegmentFlag);
         debug_msg(temp);
      }
      for (i=0; i<SegSize; i++) {
         /*
          * Note the first 2 bytes get written in the header section
          * it will get overwritten, this is easier than any sepcial handling
          * of offsets
          */ 
         CameraBuffer[UART_HEADER_SIZE+MsgOffset+i-2] = SegBuf[i];
      }

      call VarRecv.putSegDone(Handle, MsgOffset);	// Done copying
      return SUCCESS;
   }

   event result_t VarRecv.recvDone(void *Handle, result_t Result) {
      uint32 TimeOverAir;
      uint16 ExtraInfo;
      ReceiveDoneTime = MyTime;
      TimeOverAir = (ReceiveDoneTime - ReceiveReqTime) * MY_CLOCK_TICK;
      sprintf(temp, "Got Camera data from Mote %5X, Time %d\r\n", 
              CurrentCameraSensor, TimeOverAir);
      debug_msg(temp);
      CameraBufferPending = true;
      // Fill in the header only
      FillUartBuffer(CameraBuffer, CurrentCameraSensor, 
                     CameraBufferSize - UART_HEADER_SIZE, CAMERA_SENSOR, 
                     SegmentFlag, NULL); 
      post SendBufferToUart();
      return SUCCESS;
   }

   void task SendNext() {
      SendCmd(CurrentCameraSensor, CMD_SEND_NEXT);
   }

   void task SendDone() {
      SendCmd(CurrentCameraSensor, CMD_DONE);
   }

   void task RetryCmd() {
      if (RetryCount > CMD_RETRY_LIMIT) {
         CaptureInProgress = false;
         RetryCount = 0;
         if (CameraBuffer) {
            call Memory.free(CameraBuffer);
            CameraBuffer = NULL;
         }
         return; 
      }

      switch (State) {
         case SEND_COLLECT_STATE:
            SendCmd(CurrentCameraSensor, CMD_COLLECT);
            break;
         case SEND_NEXT_STATE:
            SendCmd(CurrentCameraSensor, CMD_SEND_NEXT);
            break;
      }
   }


/*
 * Start of Timer Interface
 */
  event result_t MyTimer.fired() {

     uint8 i;
     uint8 sensor;
     MyTime++;
     if (NumUsedBuffers > 0) {
        post SendBufferToUart();
     }
     
     if ((ConnectedSensors < TOTAL_SENSORS) && (MyTime < NETWORK_TIMEOUT)) {
        return SUCCESS;
     }
    
     if ((State != IDLE_STATE) && 
         (MyTime > (CmdSentTime + CMD_RETRY_TIMEOUT))) {
        post RetryCmd();
     }

     // Check if any of the receivers haven't started sending data
     sensor = LastCollectRequest;	// start where we left off
     for(i=0; i<MAX_SENSORS; i++) {
        sensor++;
        if (sensor >= MAX_SENSORS) {
           sensor = 0;
        }
        
        if ((Sensors[sensor].Addr != 0) && 
            (Sensors[sensor].ReceivedData == false) &&
            ((Sensors[sensor].Type == ACCELEROMETER_SENSOR) ||
            (Sensors[sensor].Type == TEMP_SENSOR))) {
           StartStreaming(Sensors[sensor].Addr);
           LastCollectRequest = sensor;
           return SUCCESS;
        }
     }
     return SUCCESS;
  }

  void DoneSendingBuffer() {
        SendingToUart = false;
        State = IDLE_STATE;
#if 0
        sprintf(temp, "DMA Done %d, %d, %d, %d\r\n", SendingCameraBuffer,
                SegmentFlag, CaptureInProgress);
        debug_msg(temp);
#endif
        if (SendingCameraBuffer == true) {
           CameraBufferPending = false;
           SendingCameraBuffer = false; // Done sending to PC
           BulkRecvInProgress = false;	// Allow new fragments
           call Memory.free(CameraBuffer);
           CameraBuffer = NULL;
           if (SegmentFlag == END_OF_PIC) {
              CaptureInProgress = false;
              post SendDone();
           } else {
              State = SEND_NEXT_STATE;
              post SendNext();
           }
        } else {
           // Remove entry at head of queue
           Head++;
           if (Head == NumUartBuffers) {
              Head = 0;
           }
           NumUsedBuffers--;

           // Check if more buffers to send
        }
   }

/*
 * HPLDMAUart
 */
#if SEND_SAMPLE_TO_UART

  async event uint8* HPLDMA.DMAGetDone(uint8 *data, uint16 Bytes) {
    
      return TOSBuffer->UARTRxBuffer;
  }

  async event result_t HPLDMA.DMAPutDone(uint8 *data) {
     DoneSendingBuffer();
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

/*
 * BluSH app support
 */
#if DEBUG_ON
  command BluSH_result_t app_collect.getName(char* buff, uint8_t len ){
      strcpy( buff, "collect" );
      return BLUSH_SUCCESS_DONE;
  }
  
  command BluSH_result_t app_collect.callApp( char* cmdBuff, uint8_t cmdLen,
                                       char* resBuff, uint8_t resLen ){
      CurrentCameraSensor = GetFirstSensor(CAMERA_SENSOR);
      if (CurrentCameraSensor == 0) {
         debug_msg("No Camera Sensors found \r\n");
      } else if ((State != IDLE_STATE) || (CaptureInProgress)) {
         debug_msg("Not in Idle state \r\n");
      } else {
         State = SEND_COLLECT_STATE;
         SendCmd(CurrentCameraSensor, CMD_COLLECT);
         CaptureInProgress = true;
      }
      return BLUSH_SUCCESS_DONE;
  }

  command BluSH_result_t app_help.getName(char* buff, uint8_t len ){
      strcpy( buff, "h" );
      return BLUSH_SUCCESS_DONE;
  }
  
  command BluSH_result_t app_help.callApp( char* cmdBuff, uint8_t cmdLen,
                                              char* resBuff, uint8_t resLen ){
      strcpy(resBuff,"App commands : \r\n");
      strcat(resBuff,"c = Collect \r\n");
      return BLUSH_SUCCESS_DONE;
  }

#endif

}
