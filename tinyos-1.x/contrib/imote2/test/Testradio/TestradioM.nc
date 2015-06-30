// $Id: TestradioM.nc,v 1.3 2006/10/10 02:43:56 lnachman Exp $

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

module TestradioM {
  provides {
    interface StdControl;
    interface BluSH_AppI as CmdRadio;
    interface BluSH_AppI as ReadRadio;
    interface BluSH_AppI as WriteRadio;
    interface BluSH_AppI as ToggleCarrier;    
    interface BluSH_AppI as ToggleTxTest;    
    interface BluSH_AppI as SetTxPower;    
    interface BluSH_AppI as ToggleOscOutput;    
  }
  uses {
    interface Timer;
    interface Leds;
    interface StdControl as RadioControl;
    interface HPLCC2420;
  }
}
implementation {

    /**
   * Initialize the component.
   * 
   * @return Always returns <code>SUCCESS</code>
   **/
  command result_t StdControl.init() {
      call Leds.init(); 
      call RadioControl.init();
      return SUCCESS;
  }


  /**
   * Start things up.  This just sets the rate for the clock component.
   * 
   * @return Always returns <code>SUCCESS</code>
   **/
  command result_t StdControl.start() {
    // Start a repeating timer that fires every 1000ms
      call RadioControl.start();
      TOSH_SET_CC_VREN_PIN();
      TOSH_uwait(600);

      TOSH_CLR_CC_RSTN_PIN();
      TOSH_wait();
      TOSH_SET_CC_RSTN_PIN();
      TOSH_wait();
      return call Timer.start(TIMER_REPEAT, 1000);
  }

  /**
   * Halt execution of the application.
   * This just disables the clock component.
   * 
   * @return Always returns <code>SUCCESS</code>
   **/
  command result_t StdControl.stop() {
      call RadioControl.stop();
      return call Timer.stop();
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

  command BluSH_result_t CmdRadio.getName(char *buff, uint8_t len){

      const char name[] = "CmdRadio";
      strcpy(buff,name);
      return BLUSH_SUCCESS_DONE;
}

  command BluSH_result_t CmdRadio.callApp(char *cmdBuff, uint8_t cmdLen,
                                                  char *resBuff, uint8_t resLen){
      uint32_t cmd;
      uint8_t result;
      
      if(strlen(cmdBuff) <10){
          sprintf(resBuff,"Please enter a command #\r\n");
      }
      else{
          sscanf(cmdBuff,"CmdRadio %x", &cmd);
          sprintf(resBuff,"Sending Radio Command %#x\r\n",cmd);
          result = call HPLCC2420.cmd(cmd);
          trace(DBG_USR1,"result = %#x\r\n",result);
      }
      return BLUSH_SUCCESS_DONE;
  }
  command BluSH_result_t WriteRadio.getName(char *buff, uint8_t len){

      const char name[] = "WriteRadio";
      strcpy(buff,name);
      return BLUSH_SUCCESS_DONE;
}

  command BluSH_result_t WriteRadio.callApp(char *cmdBuff, uint8_t cmdLen,
                                                  char *resBuff, uint8_t resLen){
      uint8_t result;
      
      uint32_t addr, data;
      
      if(strlen(cmdBuff) <12){
          sprintf(resBuff,"WriteRadio <addr> <data>\r\n");
      }
      else{
          sscanf(cmdBuff,"WriteRadio %x %x", &addr, &data);
          sprintf(resBuff,"Writing %#x to [%#x]\r\n",data, addr);
          result = call HPLCC2420.write(addr, data);
          trace(DBG_USR1,"result = %#x\r\n",result);
      }
      return BLUSH_SUCCESS_DONE;
  }

  command BluSH_result_t ReadRadio.getName(char *buff, uint8_t len){

      const char name[] = "ReadRadio";
      strcpy(buff,name);
      return BLUSH_SUCCESS_DONE;
}

  command BluSH_result_t ReadRadio.callApp(char *cmdBuff, uint8_t cmdLen,
                                                  char *resBuff, uint8_t resLen){
      uint32_t addr;
      uint16_t result;

      if(strlen(cmdBuff) <11){
          sprintf(resBuff,"ReadRadio <addr>\r\n");
      }
      else{
          sscanf(cmdBuff,"ReadRadio %x", &addr);
          sprintf(resBuff,"Reading Radio [%#x]\r\n",addr);
          result = call HPLCC2420.read(addr);
          trace(DBG_USR1,"result = %#x\r\n",result);
      }
      return BLUSH_SUCCESS_DONE;
  }

  command BluSH_result_t ToggleCarrier.getName(char *buff, uint8_t len){

      const char name[] = "ToggleCarrier";
      strcpy(buff,name);
      return BLUSH_SUCCESS_DONE;
}

  command BluSH_result_t ToggleCarrier.callApp(char *cmdBuff, uint8_t cmdLen,
                                                  char *resBuff, uint8_t resLen){
    static int status = 0;  
    uint16_t result;
    
    if(status == 0){
      
      trace(DBG_USR1,"TurningOnCarrier\r\n");
      //things we need to do:
      //turn on the OSC (0x01
      //set MDMCTRL1.TX_MODE(0x12) to 2
      //write 0x1800 to DACTST (0x2E)
      //issue STXON command (0x04)
      result = call HPLCC2420.cmd(CC2420_SXOSCON);
      result = call HPLCC2420.write(CC2420_MDMCTRL1, 0x2<<2);
      result = call HPLCC2420.write(CC2420_DACTST, 0x1800);
      result = call HPLCC2420.cmd(CC2420_STXON);
      status =1;
    }
    else{
      trace(DBG_USR1,"TurningOffCarrier\r\n");
      result = call HPLCC2420.cmd(CC2420_SXOSCOFF);
      status =0;
    }
    return BLUSH_SUCCESS_DONE;
  }
  command BluSH_result_t ToggleTxTest.getName(char *buff, uint8_t len){

      const char name[] = "ToggleTxTest";
      strcpy(buff,name);
      return BLUSH_SUCCESS_DONE;
  }

  command BluSH_result_t ToggleTxTest.callApp(char *cmdBuff, uint8_t cmdLen,
                                                  char *resBuff, uint8_t resLen){
    
    static int status = 0;  
    uint16_t result;
    
    if(status == 0){
      
      trace(DBG_USR1,"TurningOnTxTest\r\n");
      //things we need to do:
      //turn on the OSC (0x01
      //set MDMCTRL1.TX_MODE(0x12) to 2
      //write 0x1800 to DACTST (0x2E)
      //issue STXON command (0x04)
      result = call HPLCC2420.cmd(CC2420_SXOSCON);
      result = call HPLCC2420.write(CC2420_MDMCTRL1, 0x3<<2);
      result = call HPLCC2420.cmd(CC2420_STXON);
      status =1;
    }
    else{
      trace(DBG_USR1,"TurningOffTxTest\r\n");
      result = call HPLCC2420.cmd(CC2420_SXOSCOFF);
      status =0;
    }
    return BLUSH_SUCCESS_DONE;
  }
  
  command BluSH_result_t SetTxPower.getName(char *buff, uint8_t len){

      const char name[] = "SetTxPower";
      strcpy(buff,name);
      return BLUSH_SUCCESS_DONE;
  }

  command BluSH_result_t SetTxPower.callApp(char *cmdBuff, uint8_t cmdLen,
                                                  char *resBuff, uint8_t resLen){
      uint8_t result;
      
      uint32_t addr, data;
      
      if(strlen(cmdBuff) <12){
          sprintf(resBuff,"SetTxPower <0-7>\r\n");
      }
      else{
          sscanf(cmdBuff,"SetTxPower %d", &data);
	  switch(data){
	  case 0:
	    data = 0xA0E3;
	    break; 
	  case 1: 
	    data = 0xA0E7;
	    break;
	  case 2:
	    data = 0xA0EB;
	    break;
	  case 3:
	    data = 0xA0EF;
	    break;
	  case 4:
	    data = 0xA0F3;
	    break;
	  case 5:
	    data = 0xA0F7;
	    break;
	  case 6:
	    data = 0xA0FB;
	    break;
	  case 7:
	    data=0xA0FF;
	    break;
	  }
	  result = call HPLCC2420.write(CC2420_TXCTRL, data);
          result = call HPLCC2420.read(CC2420_TXCTRL);
	  trace(DBG_USR1,"Set TxPower to %#x \r\n",result);
      }
      return BLUSH_SUCCESS_DONE;
  }

  command BluSH_result_t ToggleOscOutput.getName(char *buff, uint8_t len){

      const char name[] = "ToggleOscOutput";
      strcpy(buff,name);
      return BLUSH_SUCCESS_DONE;
  }

  command BluSH_result_t ToggleOscOutput.callApp(char *cmdBuff, uint8_t cmdLen,
                                                  char *resBuff, uint8_t resLen){
    
    static int status = 0;  
    uint16_t result;
    
    if(status == 0){
      
      trace(DBG_USR1,"Outputting 8MHz Oscillator on SFD\r\n");
      //things we need to do:
      //turn on the OSC (0x01
      //set MDMCTRL1.TX_MODE(0x12) to 2
      //write 0x1800 to DACTST (0x2E)
      //issue STXON command (0x04)
      result = call HPLCC2420.cmd(CC2420_SXOSCON);
      result = call HPLCC2420.write(CC2420_IOCFG1, 23<<5);
      status =1;
    }
    else{
      trace(DBG_USR1,"Turning off 8MHz Oscillator output from SFD\r\n");
      result = call HPLCC2420.write(CC2420_IOCFG1, 0);
      status =0;
    }
    return BLUSH_SUCCESS_DONE;
  }
  

}

