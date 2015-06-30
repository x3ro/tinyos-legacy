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

module TempSensorM 
{
    uses {
      interface StdControl as TempSensorControl;
      interface ADC as HumSensor;
      interface ADC as TempSensor;
      interface StdControl as NetworkControl;
      interface NetworkCommand;
      interface NetworkPacket;
      interface Timer;
    }
    provides interface StdControl;

}

implementation 
{

#define CMD_START 0	// Start sending data, extra info = Delay
#define CMD_STOP  1	// Stop sending data

typedef struct tTempSample {
   uint32 Temp;
   uint32 Humidity;
} tTempSample;

typedef struct tRequestPacketHeader {
   uint8 cmd;
   uint8 info1;
   uint8 info2;
   uint8 info3;
} tRequestPacketHeader;

    uint32 MyTime, retry, LastDataTransmission;
    uint8 DataDelay;
    char *SendBuffer;      // data to post to display device
    uint32_t Channel;           // Mote ID
    uint16_t temperature, humidity;
    uint32  DataRequestor; // Other node ID which is requesting the sensor data
    uint32 ThisNodeID;
    bool   Streaming;

    command result_t StdControl.init()
        {
            retry = 0;
            MyTime = 0;
            LastDataTransmission = 0;
            temperature = 70;
            humidity = 30;
            Streaming = false;
            call TempSensorControl.init();
            call NetworkControl.init();
            call NetworkCommand.SetAppName("17F");
            call NetworkPacket.Initialize();
            
            return SUCCESS;
        }
    
    
    command result_t StdControl.start() 
        {
            SendBuffer = call NetworkPacket.AllocateBuffer(16);
            
            call NetworkControl.start();
            call TempSensorControl.start();
            call Timer.start(TIMER_REPEAT, 1000);
            call NetworkCommand.SetProperty(NETWORK_PROPERTY_APP_SENSIRION);
  
            return SUCCESS;
        }
    
    command result_t StdControl.stop() 
        {
            call TempSensorControl.stop();
            call NetworkControl.stop();
            call NetworkPacket.ReleaseBuffer(SendBuffer);
            return SUCCESS;
        }
    
    event result_t NetworkPacket.SendDone(char *data) 
        {
            call NetworkPacket.ReleaseBuffer(data);
            return SUCCESS;
        }
        

    task void SendSensorData() {
      tTempSample *Sample;
      char *buffer;
      result_t status; 

      buffer = call NetworkPacket.AllocateBuffer(sizeof(tTempSample));
      if (buffer == NULL) {
         return;
      }

      Sample = (tTempSample *) buffer;
      Sample->Temp = (uint32) temperature;
      Sample->Humidity = (uint32) humidity;

      status = call NetworkPacket.Send(DataRequestor, buffer, sizeof(tTempSample));
      if (status == FAIL) {
        call NetworkPacket.ReleaseBuffer(buffer);
        return;
      }
      LastDataTransmission = MyTime;
    }
        
    event result_t NetworkPacket.Receive( uint32 Source, uint8 *Data,
                                          uint16 Length) {

      tRequestPacketHeader *Request;

      Request = (tRequestPacketHeader *) Data;

      if (Request->cmd == CMD_START) {
         DataDelay = Request->info1;
         DataRequestor = Source;
         Streaming = true;
      } else if (Request->cmd == CMD_STOP) {
         Streaming = false;
      }

      return SUCCESS;
    }


    /*
     *Start of Clock interface
     */


    task void ReadSensor() {
       call TempSensor.getData();
    }
    
    event result_t Timer.fired() {
      MyTime++;

      // read sensor every 4 seconds, independent of when we poll it for now
      if ((MyTime & 3) == 0) {
         post ReadSensor();
      }

      if (Streaming && (MyTime > (LastDataTransmission + DataDelay))) {
         post SendSensorData();
         return SUCCESS;
      }
    }

    /*
     *End of Clock interface
     */

     
/*
 * Start of Sensor interface
 */
    async event result_t HumSensor.dataReady(uint16_t HumData)
        {
            char newName[20];
            humidity = HumData;
            sprintf(newName,"%02dF %02d%%",temperature, HumData);
            call NetworkCommand.SetAppName(newName);
            return SUCCESS;
        }
    
    task void ReadHumidity()
        {
            call HumSensor.getData();
        }

    async event result_t TempSensor.dataReady(uint16_t tempData)
        {
            temperature = tempData;
            post ReadHumidity();
            return SUCCESS;
        }

#if 0
    event result_t TempError.error(uint8_t token)
        {
            return SUCCESS;
        }

    event result_t HumError.error(uint8_t token)
        {
            return SUCCESS;
        }
    
#endif

/*
 * End of Sensor interface
 */
      

/*
 * Start of NetworkCommand interface.
 */
        
    event result_t NetworkCommand.CommandResult( uint32 Command, uint32 value) 
        {
            return SUCCESS;
        }
    
/*
 * End of NetworkCommand interface.
 */
    
}
