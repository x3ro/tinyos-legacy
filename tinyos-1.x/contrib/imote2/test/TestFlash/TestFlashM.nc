// $Id: TestFlashM.nc,v 1.3 2007/03/05 06:20:52 lnachman Exp $

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

module TestFlashM {
  provides {
    interface StdControl;
    interface BluSH_AppI as writeFlash;
    interface BluSH_AppI as eraseFlash;	
    interface BluSH_AppI as verifyEraseFlash;
    interface BluSH_AppI as verifyWriteFlash;   
    interface BluSH_AppI as stressTest;   
  }
  uses {
    interface Timer;
    interface Leds;
    interface Flash;
  }
}
implementation {

    /**
   * Initialize the component.
   * 
   * @return Always returns <code>SUCCESS</code>
   **/
  
  //I'm being lazy for now....UARTBUFFERLEN MUST BE 2x NUMSAMPLES
#define UARTBUFFERLEN (20000)
#define NUMSAMPLES (10000)  
  
  uint8_t dataBuffer[UARTBUFFERLEN];
  uint16_t dataBufferPos = 0;
  uint8_t stressTestEnable = 0,stressTestCount = 0;
  
  command result_t StdControl.init() {
    return call Leds.init();
  }


  /**
   * Start things up.  This just sets the rate for the clock component.
   * 
   * @return Always returns <code>SUCCESS</code>
   **/
  command result_t StdControl.start() {
    return call Timer.start(TIMER_REPEAT, 5000);
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
    if(stressTestEnable && stressTestCount<20){
      call eraseFlash.callApp(NULL,0,NULL,0);
      call verifyEraseFlash.callApp(NULL,0,NULL,0);
      call writeFlash.callApp(NULL,0,NULL,0);
      call verifyWriteFlash.callApp(NULL,0,NULL,0);
      stressTestCount++;
    }      
    return SUCCESS;
  }
  
  command BluSH_result_t eraseFlash.getName(char *buff, uint8_t len){

      const char name[] = "eraseFlash";
      strcpy(buff,name);
      return BLUSH_SUCCESS_DONE;
  }

  command BluSH_result_t eraseFlash.callApp(char *cmdBuff, uint8_t cmdLen,
					    char *resBuff, uint8_t resLen){
    result_t result;
    
    result = call Flash.erase(0x200000);
    trace(DBG_USR1,"eraseFlash returned %d\r\n",result);
    return BLUSH_SUCCESS_DONE;
  }

    command BluSH_result_t verifyEraseFlash.getName(char *buff, 
						    uint8_t len){
      const char name[] = "verifyEraseFlash";
      strcpy(buff,name);
      return BLUSH_SUCCESS_DONE;
  }

  command BluSH_result_t verifyEraseFlash.callApp(char *cmdBuff, 
						  uint8_t cmdLen,
                                                  char *resBuff, 
						  uint8_t resLen){
    uint32_t i;
    uint32_t *address = (uint32_t *)0x200000;
    for (i=0; i<32768; i++){
      if(*address != 0xFFFFFFFF){
	trace(DBG_USR1,"verifyErase failed at address %#x\r\n",(uint32_t)address);
	return BLUSH_SUCCESS_DONE;
      }
    }
    trace(DBG_USR1,"verifyErase succeeded!\r\n");
    return BLUSH_SUCCESS_DONE;
  }
  



  command BluSH_result_t writeFlash.getName(char *buff, uint8_t len){

      const char name[] = "writeFlash";
      strcpy(buff,name);
      return BLUSH_SUCCESS_DONE;
  }
  
  command BluSH_result_t writeFlash.callApp(char *cmdBuff, 
					    uint8_t cmdLen,
					    char *resBuff, 
					    uint8_t resLen){
    result_t result;
    uint32_t i;
    static uint32_t offset = 0;
    
    for(i=0;i<UARTBUFFERLEN;i++){
      dataBuffer[i]= i+offset;
    }
    offset=i;
    result = call Flash.write(0x200000,dataBuffer,UARTBUFFERLEN);
    trace(DBG_USR1,"writeFlash returned %d\r\n",result);
    return BLUSH_SUCCESS_DONE;
  }

  command BluSH_result_t verifyWriteFlash.getName(char *buff, uint8_t len){

    const char name[] = "verifyWriteFlash";
      strcpy(buff,name);
      return BLUSH_SUCCESS_DONE;
  }

  command BluSH_result_t verifyWriteFlash.callApp(char *cmdBuff, 
						  uint8_t cmdLen,
                                                  char *resBuff, 
						  uint8_t resLen){
    uint32_t i;
    uint8_t *address = (uint8_t *)0x200000;
    for (i=0; i<UARTBUFFERLEN; i++){
      if(address[i] != dataBuffer[i]){
	trace(DBG_USR1,"verifyWrite failed at address %#x\r\n",
		(uint32_t)address);
	return BLUSH_SUCCESS_DONE;
      }
    }
    trace(DBG_USR1,"verifyWrite succeeded!\r\n");
    return BLUSH_SUCCESS_DONE;
  }

  command BluSH_result_t stressTest.getName(char *buff, 
						    uint8_t len){
      const char name[] = "stressTest";
      strcpy(buff,name);
      return BLUSH_SUCCESS_DONE;
  }

  command BluSH_result_t stressTest.callApp(char *cmdBuff, 
					    uint8_t cmdLen,
					    char *resBuff, 
					    uint8_t resLen){
    stressTestEnable = !stressTestEnable;
    if(stressTestEnable){
      stressTestCount = 0;
      trace(DBG_USR1,"StessTest Enabled\r\n");
    }
    else{
      trace(DBG_USR1,"StessTest Disabled\r\n");
    }
    return BLUSH_SUCCESS_DONE;
  }


}

