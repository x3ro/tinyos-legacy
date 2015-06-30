/*
 * Copyright (c) 2007, Intel Corporation
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
 *
 * Author:  Adrian Burns
 *          November, 2007
 */

 /***********************************************************************************

   This SerialCommandParser library is a transport independent command parser.
   It enables sensors to be configured, commanded, and controlled through 
   simple ASCII commands.

 ***********************************************************************************/

includes Message;

module SerialCommandParserM {
  provides {
    interface SerialCommandParser;
    interface StdControl;
  }
  uses{
    interface MessagePool;
    interface SensorControl;
    interface Leds;
#ifdef ID_CHIP
    interface IDChip;
#endif
    interface InternalFlash;
  }
}

implementation {

  /******************************************************************************/
  /* below are the currently supported commands                                 */
  /* commands end with a <CR>, response format is <CR><LF><RESP><CR><LF>        */
  /******************************************************************************/

  #define BS_STRING                "BS"
  #define ENTER_STRING             "+++"
  #define EXIT_STRING              "---"
  #define SET_COMMAND              'S'
  #define GET_COMMAND              'G'

  #define GENERIC                  'G'
    #define GENERIC_ID               'I' /* "BSGIG" gets the board id (from DS2411) */
    #define GENERIC_NAME             'N' /* "BSGNS:NAME" sets name of sensor to NAME, "BSGNG" gets the NAME */
    #define GENERIC_STATUS           'S' /* "BSGSG" gets sensor status*/

  #define CONTROL                  'C'
    #define RADIO_STREAMING_BEGIN    'S' /* "BSCS" starts streaming */
    #define RADIO_STREAMING_END      'E' /* "BSCE" ends streaming */
    #define SD_CARD_LOGGING_BEGIN    'L' /* "BSCL" starts logging to micro SD card */
    #define SD_CARD_LOGGING_END      'H' /* "BSCH" halts logging to micro SD card */
    #define SD_CARD_GET_DATA         'D' /* "BSCD" gets data from micro SD card */
    #define SAMPLE_FREQUENCY         'F' /* "BSCFS:500" sets sample frequency to 500HZ, "BSCFG" gets sample frequency */

  #define CALIBRATION              'K'
    #define CALIBRATION_ACCEL        'A' /* "BSKAS:112233112233112233445566778899" */
    #define CALIBRATION_GYRO         'G' /* "BSKGG, gets the gyro calibration data */
    #define CALIBRATION_MAGNETOMETER 'M' /* same as Accel & Gyro above */

  enum cmdResponses{
    COMMAND_MODE,
    EXIT,
    OK,
    ERROR,
    UNRECOGNISED
  };

  /* NV = Non Volatile Memory - Information Memory on the MSP430 */
  enum nvDataElements{
    NV_ACCEL_CALIBRATION = 0,
    NV_GYRO_CALIBRATION = 1,
    NV_MAG_CALIBRATION = 2,
    NV_SENSOR_NAME = 3,
    NUM_NV_ITEMS = 4,
    SENSOR_NAME_SIZE = 11, /* first byte = NV item set or not, 10 bytes of data follow */
    CALIB_BLOCK_SIZE = 16, /* first byte = NV item set or not, 3 offset, 3 Sensitivity, 9 allignment maxrix */
  };

  uint8_t nvInfoMemMap[NUM_NV_ITEMS][3] = {
    {NV_ACCEL_CALIBRATION, 0, CALIB_BLOCK_SIZE},
    {NV_GYRO_CALIBRATION, 16, CALIB_BLOCK_SIZE},
    {NV_MAG_CALIBRATION, 32, CALIB_BLOCK_SIZE},
    {NV_SENSOR_NAME, 48, SENSOR_NAME_SIZE},
  };
  uint8_t nvDataBuf[CALIB_BLOCK_SIZE];

  bool parserEnabled, streaming, logging;
  norace struct Message * commandMsg;

  result_t handleEnterExit();
  uint8_t parseCommand(uint8_t *cmd, uint8_t cmdLen);

  command result_t StdControl.init(){
    /* be careful - MessagePool.init(); is already called in RovingNetworksM */
    call Leds.init();
    return SUCCESS;
  }

  command result_t StdControl.start(){
    commandMsg = call MessagePool.alloc();
    /* turn on the command interpreter to begin with */
    parserEnabled = TRUE;
    streaming = FALSE;
    logging = FALSE;
    return SUCCESS;
  }

  command result_t StdControl.stop(){
    call MessagePool.free(commandMsg);
    parserEnabled = FALSE;
    return SUCCESS;
  }

  void sendResponse(uint8_t response) {
    result_t result;
   
    switch ( response ) {
      case COMMAND_MODE:
        result = signal SerialCommandParser.responseReady("\r\nOK\r\nCOMMAND MODE\r\n", 20);
        break;
      case EXIT:
        result = signal SerialCommandParser.responseReady("\r\nOK\r\nEXIT\r\n", 12);
        break;
      case OK:
        result = signal SerialCommandParser.responseReady("\r\nOK\r\n", 6);
        break;
      case ERROR:
        result = signal SerialCommandParser.responseReady("\r\nERROR\r\n", 9);
        break;
      case UNRECOGNISED:
        result = signal SerialCommandParser.responseReady("\r\n?\r\n", 5);
        break;
        default:
          return;
      }
  }

  task void handleCommand() {
    uint8_t result;
    uint8_t *buf = NULL;
    buf = msg_get_pointer(commandMsg, 0);
    
    if (msg_get_length(commandMsg) <= 1) {
        msg_clear(commandMsg);
        sendResponse(UNRECOGNISED);
        return;
    }
    
    if(parserEnabled) {      
      if((result = handleEnterExit()) == SUCCESS) return;
      msg_append_uint8(commandMsg, 0); //add in a null for string manipulation
      result = parseCommand(buf, (msg_get_length(commandMsg)-1));
      msg_clear(commandMsg);
      
      /* send ERROR response now, otherwise response will be sent when command has executed */
      if(result == ERROR)
        sendResponse(ERROR);
      if(result == UNRECOGNISED)
        sendResponse(UNRECOGNISED);
    }
    else {
      if((strncmp(buf, ENTER_STRING, strlen(ENTER_STRING)) == 0)) {
        parserEnabled = TRUE;
        msg_clear(commandMsg);
        sendResponse(COMMAND_MODE);
        return;
      }
      msg_clear(commandMsg);
    }
  }

  command void SerialCommandParser.handleByte(uint8_t data) {
    if(isalpha(data)) {
      msg_append_uint8(commandMsg, data);
    }
    else {
      if (data == 0x0D) /* <CR> */
        post handleCommand();
      else
        msg_append_uint8(commandMsg, data);
    }
  }

  result_t handleEnterExit() {
    if(msg_cmp_buf(commandMsg, 0, ENTER_STRING, strlen(ENTER_STRING))) {
      msg_clear(commandMsg);
      sendResponse(OK);
      return SUCCESS;
    }
    if(msg_cmp_buf(commandMsg, 0, EXIT_STRING, strlen(EXIT_STRING))) {
      parserEnabled = FALSE;
      msg_clear(commandMsg);
      sendResponse(EXIT);
      return SUCCESS;
    }
    return FAIL;
  }
  
  task void radioStartStreaming() {
    result_t result;
    result = call SensorControl.startStreaming();
    if(result == FAIL) 
      sendResponse(ERROR);
  }

  async event void SensorControl.streamingStarted(result_t result) {
    if(result == SUCCESS) {
      sendResponse(OK);
      streaming = TRUE;
    }
    else
      sendResponse(ERROR);
  }

  task void radioStopStreaming() {
    result_t result;
    result = call SensorControl.stopStreaming();
    if(result == FAIL) 
      sendResponse(ERROR);
  }

  async event void SensorControl.streamingStopped(result_t result) {
    if(result == SUCCESS) {
      sendResponse(OK);
      streaming = FALSE;
    }
    else
      sendResponse(ERROR);
  }

  task void startLogging() {
    /* TBD */
    sendResponse(ERROR);
  }

  async event void SensorControl.loggingStarted(result_t result) {
    if(result == SUCCESS) {
      sendResponse(OK);
      logging = TRUE;
    }
    else
      sendResponse(ERROR);
  }

  task void stopLogging() {
    /* TBD */
    sendResponse(ERROR);
  }

  async event void SensorControl.loggingStopped(result_t result) {
    if(result == SUCCESS) {
      sendResponse(OK);
      logging = FALSE;
    }
    else
      sendResponse(ERROR);
  }

  task void getCardData() {
    /* TBD */
    sendResponse(ERROR);
  }

  async event void SensorControl.cardTransferComplete(result_t result) {
  }

  task void getSampleFrequency() {
    uint8_t respBuf[13];
    uint16_t freq = call SensorControl.getSampleFrequency();
    
    memcpy(respBuf, "\r\nOK\r\n", 6);
    snprintf(&respBuf[6], 7, "%04d\r\n", freq);
    signal SerialCommandParser.responseReady(respBuf, (sizeof(respBuf)-1));
  }
    
  task void getSensorID() {
    result_t result=FAIL;
    uint8_t respBuf[21];
    uint8_t chipID[6];
    
#ifdef ID_CHIP
    result = call IDChip.read(chipID);  // Fill in the last 6 bytes
#endif
    if(result == FAIL)
      sendResponse(ERROR);
    else {
      memcpy(respBuf, "\r\nOK\r\n", 6);
      snprintf(&respBuf[6], 15, "%02X%02X%02X%02X%02X%02X\r\n", 
               chipID[0], chipID[1], chipID[2], chipID[3], chipID[4], chipID[5] );
      signal SerialCommandParser.responseReady(respBuf, (sizeof(respBuf)-1));
    }
  }

  async event void SensorControl.sampleFrequencyChanged(result_t result) {
    if(result == SUCCESS) 
      sendResponse(OK);
    else
      sendResponse(ERROR);
  }

  task void getSensorStatus() {
    uint8_t respBuf[11];
    memcpy(respBuf, "\r\nOK\r\n", 6);
    respBuf[6] = call SensorControl.getActiveRadio();
    respBuf[7] = streaming ? 'S' : 'O';
    respBuf[8] = logging ? 'L' : 'O';
    memcpy(&respBuf[9], "\r\n", 2);
    signal SerialCommandParser.responseReady(respBuf, sizeof(respBuf));
  }

  task void setSensorName() {
    result_t result;
    result = call InternalFlash.write((void*)nvInfoMemMap[NV_SENSOR_NAME][1], (void*)nvDataBuf,
                                      (uint16_t)nvInfoMemMap[NV_SENSOR_NAME][2]);
    if(result == FAIL)
      sendResponse(ERROR);
    else
      sendResponse(OK);
  }

  task void getSensorName() {
    result_t result;
    uint8_t buf[SENSOR_NAME_SIZE];
    uint8_t respBuf[18];
    uint8_t* ptr = buf;
    uint16_t i;
    
    result = call InternalFlash.read((void*)nvInfoMemMap[NV_SENSOR_NAME][1],
                                     (void*)ptr,(uint16_t)nvInfoMemMap[NV_SENSOR_NAME][2]);
    /* first read from NV indicates whether the NV item is set (0x01) or not (0xFF) */
    if(result == FAIL || ptr[0] != 0x01)
      sendResponse(ERROR);
    else {
      for(i=1; i<SENSOR_NAME_SIZE; i++) {
        if ( (ptr[i] >= '0') && (ptr[i] <= 'Z') );
        else break;
    }
    memcpy(respBuf, "\r\nOK\r\n", 6);
    memcpy(&respBuf[6], &buf[1], (i-1));
    memcpy(&respBuf[i+5], "\r\n", 2);
    signal SerialCommandParser.responseReady(respBuf, (i+7));
    }
  }

  void readCalibrationData(void* startAddr, uint16_t size) {
    result_t result;
    uint8_t buf[CALIB_BLOCK_SIZE];
    uint8_t respBuf[39];
    uint8_t* ptr = buf;

    result = call InternalFlash.read(startAddr, (void*)ptr, size);
    /* first read from NV indicates whether the NV item is set (0x01) or not (0xFF) */
    if(result == FAIL || ptr[0] != 0x01)
      sendResponse(ERROR);
    else {
      memcpy(respBuf, "\r\nOK\r\n", 6);
      snprintf(&respBuf[6], 33, "%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X\r\n", 
               ptr[1], ptr[2], ptr[3], ptr[4], ptr[5], ptr[6], ptr[7], 
               ptr[8], ptr[9], ptr[10], ptr[11], ptr[12], ptr[13], ptr[14], ptr[15] );
      signal SerialCommandParser.responseReady(respBuf, (sizeof(respBuf)-1));
    }
  }

  void writeCalibrationData(void* startAddr, uint16_t size) {
    result_t result;
    result = call InternalFlash.write(startAddr, (void*)nvDataBuf, size);
    if(result == FAIL)
      sendResponse(ERROR);
    else
      sendResponse(OK);
  }

  task void getAccelCalibrationData() {
    readCalibrationData((void*)nvInfoMemMap[NV_ACCEL_CALIBRATION][1],
                        (uint16_t)nvInfoMemMap[NV_ACCEL_CALIBRATION][2]);
  }

  task void setAccelCalibrationData() {
    writeCalibrationData((void*)nvInfoMemMap[NV_ACCEL_CALIBRATION][1],
                        (uint16_t)nvInfoMemMap[NV_ACCEL_CALIBRATION][2]);
  }

  task void getGyroCalibrationData() {
    readCalibrationData((void*)nvInfoMemMap[NV_GYRO_CALIBRATION][1],
                        (uint16_t)nvInfoMemMap[NV_GYRO_CALIBRATION][2]);
  }

  task void setGyroCalibrationData() {
    writeCalibrationData((void*)nvInfoMemMap[NV_GYRO_CALIBRATION][1],
                        (uint16_t)nvInfoMemMap[NV_GYRO_CALIBRATION][2]);
  }

  task void getMagCalibrationData() {
    readCalibrationData((void*)nvInfoMemMap[NV_MAG_CALIBRATION][1],
                        (uint16_t)nvInfoMemMap[NV_MAG_CALIBRATION][2]);
  }

  task void setMagCalibrationData() {
    writeCalibrationData((void*)nvInfoMemMap[NV_MAG_CALIBRATION][1],
                        (uint16_t)nvInfoMemMap[NV_MAG_CALIBRATION][2]);
  }

  uint8_t getDigit( uint8_t c ){
    if ( (c >= '0') && (c <= '9') )
      return( c - '0' );
    if ( (c >= 'A') && (c <= 'F') )
      return( c - 'A' + 10 );
    return( 0 );
  }

  uint8_t parseCommand(uint8_t *cmd, uint8_t cmdLen) {
    uint16_t   i, j, arg1;
      
    if ((parserEnabled == FALSE) || (cmd == NULL))
      return ERROR;

    /* go no further if command isnt starting with "BS" -> Body Sensor command */
    if(!(strncmp(cmd, BS_STRING, strlen(BS_STRING)) == 0))
      return UNRECOGNISED;
    
    if(cmdLen == strlen(BS_STRING)) {
      sendResponse(OK);
      return OK;
    }

    if(cmdLen == 3)
      return UNRECOGNISED;

    switch ( cmd[2] ) {
      case CONTROL:
        switch ( cmd[3] ) {
          case RADIO_STREAMING_BEGIN:
            post radioStartStreaming();
            return OK;
          case RADIO_STREAMING_END:
            post radioStopStreaming();
            return OK;
          case SD_CARD_LOGGING_BEGIN:
            post startLogging();
            return OK;
          case SD_CARD_LOGGING_END:
            post stopLogging();
            return OK;
          case SD_CARD_GET_DATA:
            post getCardData();
            return OK;
          case SAMPLE_FREQUENCY:
            switch ( cmd[4] ) {
              case GET_COMMAND:
                post getSampleFrequency();
                return OK;
              case SET_COMMAND:
                if((cmdLen == 5) || (cmd[5] != ':'))
                  return UNRECOGNISED;
                arg1 = atoi(cmd+6);
                call SensorControl.changeSampleFrequency(arg1);
                return OK;
            }
          default:
            return UNRECOGNISED;
        }
      break; /* CONTROL */
      
      case GENERIC:
        switch ( cmd[3] ) {
          case GENERIC_ID:
            if(cmd[4] == GET_COMMAND) {
              post getSensorID();
              return OK;
            } else 
              return UNRECOGNISED;
          case GENERIC_NAME:
            if(cmd[4] == SET_COMMAND) {
              if( (cmd[5] != ':') || (cmdLen > 16) )
                return UNRECOGNISED;
              memset(nvDataBuf, 0, sizeof(nvDataBuf));
              nvDataBuf[0] = 0x01; // to say item is set
              for(i=0; i<(cmdLen-6); i++)
                nvDataBuf[i+1] = cmd[i+6];
            }
            switch ( cmd[4] ) {
              case GET_COMMAND:
                  post getSensorName();
                  return OK;
              case SET_COMMAND:
                post setSensorName();
                return OK;
              default:
                return UNRECOGNISED;
            }
            post getSensorID();
            return OK;
          case GENERIC_STATUS:
            if(cmd[4] == GET_COMMAND) {
              post getSensorStatus();
              return OK;
            } else 
              return UNRECOGNISED;
          default:
            return UNRECOGNISED;
        }
      break; /* GENERIC */
      
      case CALIBRATION:
        if(cmd[4] == SET_COMMAND) {
          if( (cmd[5] != ':') || (cmdLen != 36) )
            return UNRECOGNISED;

          nvDataBuf[0] = 0x01; // to say item is set
          /* put the hex string into a raw data array */
          for(i=0,j=1; i<((CALIB_BLOCK_SIZE-1)*2); i+=2,j++) {
            nvDataBuf[j] = (getDigit(cmd[i+6]) << 4);
            nvDataBuf[j] |= getDigit(cmd[i+7]);
          }
        }
        switch ( cmd[3] ) {
          case CALIBRATION_ACCEL:
            switch ( cmd[4] ) {
              case GET_COMMAND:
                  post getAccelCalibrationData();
                  return OK;
              case SET_COMMAND:
                post setAccelCalibrationData();
                return OK;
              default:
                return UNRECOGNISED;
            }
          case CALIBRATION_GYRO:
            switch ( cmd[4] ) {
              case GET_COMMAND:
                  post getGyroCalibrationData();
                  return OK;
              case SET_COMMAND:
                post setGyroCalibrationData();
                return OK;
              default:
                return UNRECOGNISED;
            }
          case CALIBRATION_MAGNETOMETER:
            switch ( cmd[4] ) {
              case GET_COMMAND:
                  post getMagCalibrationData();
                  return OK;
              case SET_COMMAND:
                post setMagCalibrationData();
                return OK;
              default:
                return UNRECOGNISED;
            }
          default:
            return UNRECOGNISED;
        }
      break; /* CALIBRATION */
      default:
        return UNRECOGNISED;
    }
  }

}
