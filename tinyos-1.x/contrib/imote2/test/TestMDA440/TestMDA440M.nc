// $Id: TestMDA440M.nc,v 1.5 2006/10/10 21:51:09 lnachman Exp $

/*									tab:4
 * "Copyright (c) 2000-2003 The Regents of the University  of California.  
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY OF
 * CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 *
 * Copyright (c) 2002-2003 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */

/**
 * Implementation for Blink application.  Toggle the red LED when a
 * Timer fires.
 **/
includes trace;

module TestMDA440M {
  provides {
    interface StdControl;
    interface BluSH_AppI as ClearGPIO;
    interface BluSH_AppI as SetGPIO;	
    
    interface BluSH_AppI as TurnOffBoard;	
    interface BluSH_AppI as EnableHighSpeedChain;	
    interface BluSH_AppI as DisableHighSpeedChain;
    interface BluSH_AppI as SelectMux0Channel;
    interface BluSH_AppI as EnableLowSpeedChain;	
    interface BluSH_AppI as DisableLowSpeedChain;
    interface BluSH_AppI as SelectLowSpeedChannel;
    interface BluSH_AppI as GetData;
    interface BluSH_AppI as SetAccelIn;
    interface BluSH_AppI as SetTempIn;
    interface BluSH_AppI as SetCurrentIn;
    
    interface BluSH_AppI as StartRPMCapture;
    interface BluSH_AppI as StopRPMCapture;

    interface BluSH_AppI as ReadCal;
    interface BluSH_AppI as WriteCal;
    
  }
  uses {
    interface Timer;
    interface Leds;
    interface MDA440;
    interface HPLUART as UART;
    interface EEPROM;
  }
}
implementation {

    /**
   * Initialize the component.
   * 
   * @return Always returns <code>SUCCESS</code>
   **/
  
  //I'm being lazy for now....UARTBUFFERLEN MUST BE 2x NUMSAMPLES
#define NUMSAMPLES (16384)  
#define UARTBUFFERLEN (NUMSAMPLES*2)

  
  uint8_t dataBuffer[UARTBUFFERLEN] __attribute__((aligned(32)));
  uint32_t dataBufferPos = UARTBUFFERLEN;
  
    command result_t StdControl.init() {
      call MDA440.init();
      call UART.init();
      return call Leds.init();
  }


  /**
   * Start things up.  This just sets the rate for the clock component.
   * 
   * @return Always returns <code>SUCCESS</code>
   **/
  command result_t StdControl.start() {
    return call Timer.start(TIMER_REPEAT, 500);
    call MDA440.setAccelIn(0);
    return SUCCESS;
  }

  /**
   * Halt execution of the application.
   * This just disables the clock component.
   * 
   * @return Always returns <code>SUCCESS</code>
   **/
  command result_t StdControl.stop() {
    return call Timer.stop();
    return SUCCESS;
  }


  /**
   * Toggle the red LED in response to the <code>Timer.fired</code> event.  
   *
   * @return Always returns <code>SUCCESS</code>
   **/  
  
  event result_t Timer.fired()
  {
    call Leds.redToggle();
    return SUCCESS;
  }
  
  command BluSH_result_t ClearGPIO.getName(char *buff, uint8_t len){

      const char name[] = "ClearGPIO";
      strcpy(buff,name);
      return BLUSH_SUCCESS_DONE;
}

  command BluSH_result_t ClearGPIO.callApp(char *cmdBuff, uint8_t cmdLen,
                                                  char *resBuff, uint8_t resLen){
      uint32_t gpio;
      
      if(strlen(cmdBuff) <11){
          sprintf(resBuff,"Please enter a GPIO #\r\n");
      }
      else{
          sscanf(cmdBuff,"ClearGPIO %d", &gpio);
	  GPIO_SET_ALT_FUNC(gpio,0,GPIO_OUT);
	  CLEAR_GPIO(gpio);
	  trace(DBG_USR1,"ClearGPIO DONE\r\n",gpio);
      }
      *resBuff = 0;
      return BLUSH_SUCCESS_DONE;
  }
  command BluSH_result_t SetGPIO.getName(char *buff, uint8_t len){

      const char name[] = "SetGPIO";
      strcpy(buff,name);
      return BLUSH_SUCCESS_DONE;
}

  command BluSH_result_t SetGPIO.callApp(char *cmdBuff, uint8_t cmdLen,
                                                  char *resBuff, uint8_t resLen){
      uint32_t gpio;
      
      if(strlen(cmdBuff) <8){
          sprintf(resBuff,"Please enter a GPIO #\r\n");
      }
      else{
	sscanf(cmdBuff,"SetGPIO %d", &gpio);
	GPIO_SET_ALT_FUNC(gpio,0,GPIO_OUT);
	SET_GPIO(gpio);
	trace(DBG_USR1,"SetGPIO DONE\r\n",gpio);
      }
      *resBuff = 0;
      return BLUSH_SUCCESS_DONE;
  }
  command BluSH_result_t TurnOffBoard.getName(char *buff, uint8_t len){

      const char name[] = "TurnOffBoard";
      strcpy(buff,name);
      return BLUSH_SUCCESS_DONE;
  }

  command BluSH_result_t TurnOffBoard.callApp(char *cmdBuff, uint8_t cmdLen,
					      char *resBuff, uint8_t resLen){
    call MDA440.turnOffBoard();
    *resBuff = 0;
    trace(DBG_USR1,"Board Turned Off\r\n");
    return BLUSH_SUCCESS_DONE;
  }
  command BluSH_result_t EnableHighSpeedChain.getName(char *buff, uint8_t len){

    const char name[] = "EnableHighSpeedChain";
    strcpy(buff,name);
    return BLUSH_SUCCESS_DONE;
  }

  command BluSH_result_t EnableHighSpeedChain.callApp(char *cmdBuff, uint8_t cmdLen,
						      char *resBuff, uint8_t resLen){
    call MDA440.enableHighSpeedChain();
    trace(DBG_USR1,"High Speed Chain Enabled\r\n");
    *resBuff = 0;
    return BLUSH_SUCCESS_DONE;
  }
  command BluSH_result_t DisableHighSpeedChain.getName(char *buff, uint8_t len){

    const char name[] = "DisableHighSpeedChain";
    strcpy(buff,name);
    return BLUSH_SUCCESS_DONE;
  }

  command BluSH_result_t DisableHighSpeedChain.callApp(char *cmdBuff, uint8_t cmdLen,
						       char *resBuff, uint8_t resLen){
    call MDA440.disableHighSpeedChain();
    trace(DBG_USR1,"High Speed Chain Disabled\r\n");
    *resBuff = 0;
    return BLUSH_SUCCESS_DONE;
  }
  command BluSH_result_t SelectMux0Channel.getName(char *buff, uint8_t len){

    const char name[] = "SelectMux0Channel";
    strcpy(buff,name);
    return BLUSH_SUCCESS_DONE;
  }

  command BluSH_result_t SelectMux0Channel.callApp(char *cmdBuff, uint8_t cmdLen,
						   char *resBuff, uint8_t resLen){
    uint32_t num;
    
    if(strlen(cmdBuff) <18){
      sprintf(resBuff,"Please enter a channel #\r\n");
    }
    else{
      sscanf(cmdBuff,"SelectMux0Channel %d", &num);
      call MDA440.selectMux0Channel(num);
      trace(DBG_USR1,"Setting Mux0 Channel to %.3d\r\n",num);
    }
    *resBuff = 0;
    return BLUSH_SUCCESS_DONE;
  }

  command BluSH_result_t EnableLowSpeedChain.getName(char *buff, uint8_t len){

    const char name[] = "EnableLowSpeedChain";
    strcpy(buff,name);
    return BLUSH_SUCCESS_DONE;
  }

  command BluSH_result_t EnableLowSpeedChain.callApp(char *cmdBuff, uint8_t cmdLen,
						     char *resBuff, uint8_t resLen){
    call MDA440.enableLowSpeedChain(); 
    trace(DBG_USR1,"Low Speed Chain Enabled\r\n");
    *resBuff = 0;
    return BLUSH_SUCCESS_DONE;
  }
  command BluSH_result_t DisableLowSpeedChain.getName(char *buff, uint8_t len){

    const char name[] = "DisableLowSpeedChain";
    strcpy(buff,name);
    return BLUSH_SUCCESS_DONE;
  }

  command BluSH_result_t DisableLowSpeedChain.callApp(char *cmdBuff, uint8_t cmdLen,
						      char *resBuff, uint8_t resLen){
    call MDA440.disableLowSpeedChain();
    trace(DBG_USR1,"Low Speed Chain Disabled\r\n");
    *resBuff = 0;
    return BLUSH_SUCCESS_DONE;
  }

    command BluSH_result_t SelectLowSpeedChannel.getName(char *buff, uint8_t len){

    const char name[] = "SelectLowSpeedChannel";
    strcpy(buff,name);
    return BLUSH_SUCCESS_DONE;
  }

  command BluSH_result_t SelectLowSpeedChannel.callApp(char *cmdBuff, uint8_t cmdLen,
						       char *resBuff, uint8_t resLen){
    uint32_t num;
    
    if(strlen(cmdBuff) <22){
      sprintf(resBuff,"Please enter a channel #\r\n");
    }
    else{
      sscanf(cmdBuff,"SelectLowSpeedChannel %d", &num);
      call MDA440.selectLowSpeedChannel(num);
      trace(DBG_USR1,"Setting Low Speed Channel to %.3d\r\n",num);
    }
    *resBuff = 0;
    return BLUSH_SUCCESS_DONE;
  }
  
  command BluSH_result_t SetAccelIn.getName(char *buff, uint8_t len){
      
    const char name[] = "SetAccelIn";
    strcpy(buff,name);
    return BLUSH_SUCCESS_DONE;
  }

  command BluSH_result_t SetAccelIn.callApp(char *cmdBuff, uint8_t cmdLen,
						   char *resBuff, uint8_t resLen){
    uint32_t num;
    
    if(strlen(cmdBuff) <11){
      sprintf(resBuff,"Please enter a channel #\r\n");
    }
    else{
      sscanf(cmdBuff,"SetAccelIn %d", &num);
      call MDA440.setAccelIn(num);
      trace(DBG_USR1,"Setting Accel Channel to %.3d\r\n",num);
    }
    *resBuff = 0;
    return BLUSH_SUCCESS_DONE;
  }

  command BluSH_result_t SetTempIn.getName(char *buff, uint8_t len){
      
    const char name[] = "SetTempIn";
    strcpy(buff,name);
    return BLUSH_SUCCESS_DONE;
  }

  command BluSH_result_t SetTempIn.callApp(char *cmdBuff, uint8_t cmdLen,
						   char *resBuff, uint8_t resLen){
    uint32_t num;
    
    if(strlen(cmdBuff) <11){
      sprintf(resBuff,"Please enter a channel #\r\n");
    }
    else{
      sscanf(cmdBuff,"SetTempIn %d", &num);
      call MDA440.setTempIn(num);
      trace(DBG_USR1,"Setting Accel Channel to %.3d\r\n",num);
    }
    *resBuff = 0;
    return BLUSH_SUCCESS_DONE;
  }

  command BluSH_result_t SetCurrentIn.getName(char *buff, uint8_t len){
      
    const char name[] = "SetCurrentIn";
    strcpy(buff,name);
    return BLUSH_SUCCESS_DONE;
  }

  command BluSH_result_t SetCurrentIn.callApp(char *cmdBuff, uint8_t cmdLen,
						   char *resBuff, uint8_t resLen){
    uint32_t num;
    
    if(strlen(cmdBuff) <13){
      sprintf(resBuff,"Please enter a channel #\r\n");
    }
    else{
      sscanf(cmdBuff,"SetCurrentIn %d", &num);
      call MDA440.setCurrentIn(num);
      trace(DBG_USR1,"Setting Current Channel to %.3d\r\n",num);
      *resBuff = 0;
    }
    return BLUSH_SUCCESS_DONE;
  }
  

  command BluSH_result_t GetData.getName(char *buff, uint8_t len){
    
    const char name[] = "GetData";
    strcpy(buff,name);
    return BLUSH_SUCCESS_DONE;
  }

  task void putDataTask(){
    uint8_t * data8ptr = (uint8_t *)dataBuffer;
    if(dataBufferPos < UARTBUFFERLEN){
      call UART.put(data8ptr[dataBufferPos]);
      dataBufferPos++;
    }
  }
  
  
  command BluSH_result_t GetData.callApp(char *cmdBuff, uint8_t cmdLen,
					 char *resBuff, uint8_t resLen){
    uint32_t K;
    if(strlen(cmdBuff) > strlen("GetData ")){
      sscanf(cmdBuff,"GetData %d", &K);
      call MDA440.getSamples(dataBuffer, NUMSAMPLES, K);
      trace(DBG_USR1,"Getting %d samples decimated by %d\r\n", NUMSAMPLES,K);
    }
    else{
      call MDA440.getSamples(dataBuffer, NUMSAMPLES, 1);
      trace(DBG_USR1,"Getting %d samples\r\n", NUMSAMPLES);
    }
    return BLUSH_SUCCESS_DONE;
  }

  
  event result_t MDA440.getSamplesDone(uint8_t *buffer){
    uint16_t *temp = (uint16_t *)dataBuffer;
    trace(DBG_USR1,"got samples %#x %#x %#x %#x %#x % #x %#x %#x %#x %#x !!!\r\n", temp[0], temp[1], temp[2], temp[3], temp[4], temp[5], temp[6], temp[7], temp[8], temp[9]);
    dataBufferPos = 0;
    post putDataTask();
    return SUCCESS;
  }  

  async event result_t UART.get(uint8_t data){
    //don't care about the data
    return SUCCESS;
  }
  
 
  async event result_t UART.putDone(){
    post putDataTask();
    return SUCCESS;
  }

  command BluSH_result_t StartRPMCapture.getName(char *buff, uint8_t len){
      
    const char name[] = "StartRPMCapture";
    strcpy(buff,name);
    return BLUSH_SUCCESS_DONE;
  }

  command BluSH_result_t StartRPMCapture.callApp(char *cmdBuff, uint8_t cmdLen,
						   char *resBuff, uint8_t resLen){
    call MDA440.startTach();
    trace(DBG_USR1,"StartRPMCapture DONE\r\n");
    return BLUSH_SUCCESS_DONE;
  }

  command BluSH_result_t StopRPMCapture.getName(char *buff, uint8_t len){
      
    const char name[] = "StopRPMCapture";
    strcpy(buff,name);
    return BLUSH_SUCCESS_DONE;
  }

  command BluSH_result_t StopRPMCapture.callApp(char *cmdBuff, uint8_t cmdLen,
						   char *resBuff, uint8_t resLen){
    uint32_t totalTime, totalSamples;
    result_t res;
    res = call MDA440.stopTach(&totalTime, &totalSamples);
    
    if(res == SUCCESS && totalSamples){
      float temp;
      temp = (float)totalTime/(float)totalSamples;
      trace(DBG_USR1,"StopRPMCapture %f\r\n",195000000.0 /temp);
    }
    else{
      trace(DBG_USR1,"StopRPMCapture 0.0\r\n");
    }
    
    return BLUSH_SUCCESS_DONE;
  }

  command BluSH_result_t ReadCal.getName(char *buff, uint8_t len){
      
    const char name[] = "ReadCal";
    strcpy(buff,name);
    return BLUSH_SUCCESS_DONE;
  }

  command BluSH_result_t ReadCal.callApp(char *cmdBuff, uint8_t cmdLen,
						   char *resBuff, uint8_t resLen){
    
    uint32_t val;
    
    call EEPROM.read(0,(uint8_t *)&val,4);
    trace(DBG_USR1,"ReadCal %#x\r\n",val);
    return BLUSH_SUCCESS_DONE;
  }

  command BluSH_result_t WriteCal.getName(char *buff, uint8_t len){
      
    const char name[] = "WriteCal";
    strcpy(buff,name);
    return BLUSH_SUCCESS_DONE;
  }

  command BluSH_result_t WriteCal.callApp(char *cmdBuff, uint8_t cmdLen,
						   char *resBuff, uint8_t resLen){
    uint32_t val;
    
    if(strlen(cmdBuff) < strlen("WriteCal  ")){
      trace(DBG_USR1,"WriteCal FAIL\r\n");
    }
    else{
      sscanf(cmdBuff,"WriteCal %x",&val);
      call EEPROM.write(0,(uint8_t *)&val,4);
      trace(DBG_USR1,"WriteCal DONE\r\n");
      return BLUSH_SUCCESS_DONE;
    }
  }

}
  
