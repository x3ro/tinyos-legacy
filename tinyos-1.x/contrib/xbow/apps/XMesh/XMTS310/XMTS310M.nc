/**									tab:4
 *  IMPORTANT: READ BEFORE DOWNLOADING, COPYING, INSTALLING OR USING.  By
 *  downloading, copying, installing or using the software you agree to
 *  this license.  If you do not agree to this license, do not download,
 *  install, copy or use the software.
 *
 *  Copyright (c) 2004 Crossbow Technology, Inc.  All rights reserved. 
 *
 *  Permission to use, copy, modify, and distribute this software and its
 *  documentation for any purpose, without fee, and without written
 *  agreement is hereby granted, provided that the above copyright
 *  notice, the (updated) modification history and the author appear in
 *  all copies of this source code.
 *
 *  Permission is also granted to distribute this software under the
 *  standard BSD license as contained in the TinyOS distribution.
 *
 *  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 *  ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 *  LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
 *  PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE INTEL OR ITS
 *  CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 *  EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 *  PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 *  PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 *  LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 *  NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 *  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 *  @author Martin Turon, Alan Broad, Hu Siquan
 * 
 *  $Id: XMTS310M.nc,v 1.8 2005/01/10 05:45:07 husq Exp $
 */

/****************************************************************************
 *
 ***************************************************************************/
#include "appFeatures.h"

//includes XCommand;
includes sensorboard;

module XMTS310M {
    provides {
	interface StdControl;
    }
    uses {
// RF Mesh Networking
	interface Send;
	interface RouteControl;
#ifdef XMESHSYNC
    interface Receive as DownTree; 	
#endif    

	interface XCommand;
	
//	interface ReceiveMsg as Bcast;

// Battery    
    interface ADC as ADCBATT;
    interface StdControl as BattControl;

//Temp
	interface StdControl as TempControl;
	interface ADC as Temperature;

//Light
	interface StdControl as PhotoControl;
	interface ADC as Light;

// Mic
	interface StdControl as MicControl;
	interface Mic;
	interface ADC as MicADC;

// Sounder
	interface StdControl as Sounder;

// Accel   
	interface StdControl as AccelControl;
	interface ADC as AccelX;
	interface ADC as AccelY;

// Mag
	interface StdControl as MagControl;
	interface ADC as MagX;
	interface ADC as MagY;
	
	//interface ADCControl;   
	interface Timer;
	interface Leds;

#if FEATURE_UART_SEND
	interface SendMsg as SendUART;
	command result_t PowerMgrEnable();
	command result_t PowerMgrDisable();
#endif
    }
}

implementation {
    
    enum { START, BUSY, SOUND_DONE};
    
#define MSG_LEN  29 
    
    TOS_Msg    gMsgBuffer;
    TOS_Msg    msg_buf_radio;
    TOS_MsgPtr msg_radio;

    uint32_t   timer_rate;  
    bool       sleeping;	       // application command state

    norace XDataMsg   readings;
    
    char main_state;
    bool sound_state, sending_packet;
    
/***************************************************************************
 * Task to xmit radio message
 *
 *    msg_radio->addr = TOS_BCAST_ADDR;
 *    msg_radio->type = 0x31;
 *    msg_radio->length = MSG_LEN;
 *    msg_radio->group = TOS_AM_GROUP;
 ***************************************************************************/
    task void send_radio_msg() {
	uint8_t   i;
	uint16_t  len;
	XDataMsg *data;
	
	call Leds.yellowOn();
	// Fill the given data buffer.	    
	data = (XDataMsg*)call Send.getBuffer(msg_radio, &len);
	
	for (i = 0; i <= sizeof(XDataMsg)-1; i++) 
	    ((uint8_t*)data)[i] = ((uint8_t*)&readings)[i];
	
	data->board_id  = SENSOR_BOARD_ID;
	data->packet_id = 1;    
	data->node_id   = TOS_LOCAL_ADDRESS;
	data->parent    = call RouteControl.getParent();
#if FEATURE_UART_SEND
	if (TOS_LOCAL_ADDRESS != 0) {
	    call PowerMgrDisable();
	    TOSH_uwait(1000);
	    if (call SendUART.send(TOS_UART_ADDR, sizeof(XDataMsg), 
				   msg_radio) != SUCCESS) 
	    {
		atomic sending_packet = FALSE;
		call Leds.yellowOff();
		call PowerMgrEnable();
	    }
	} 
	else 
#endif
	{
	    // Send the RF packet!
	    if (call Send.send(msg_radio, sizeof(XDataMsg)) != SUCCESS) {
		atomic sending_packet = FALSE;
		call Leds.yellowOff();
	    }
	}

	return;
}
    
  static void initialize() {
      atomic {
	  sleeping = FALSE;
	  main_state = START;
  	  sound_state = TRUE;
	  sending_packet = FALSE;
	  timer_rate = XSENSOR_SAMPLE_RATE;
      }
  }

/****************************************************************************
 * Initialize the component. Initialize ADCControl, Leds
 *
 ****************************************************************************/
    command result_t StdControl.init() {
	
	atomic msg_radio = &msg_buf_radio;
	
    //  MAKE_BAT_MONITOR_OUTPUT();  // enable voltage ref power pin as output
    //  MAKE_ADC_INPUT();           // enable ADC7 as input
    call BattControl.init();          
// usart1 is also connected to external serial flash
// set usart1 lines to correct state
//  TOSH_MAKE_FLASH_SELECT_OUTPUT();
      TOSH_MAKE_FLASH_OUT_OUTPUT();             //tx output
      TOSH_MAKE_FLASH_CLK_OUTPUT();             //usart clk
//  TOSH_SET_FLASH_SELECT_PIN();

      call Leds.init();
      call TempControl.init();
      call PhotoControl.init();
      call MicControl.init();
      call Mic.muxSel(1);  // Set the mux so that raw microhpone output is selected
      call Mic.gainAdjust(64);  // Set the gain of the microphone. (refer to Mic) 
      call Sounder.init();
      
#ifdef MTS310
      call AccelControl.init();
      call MagControl.init();
#endif
      
      initialize();
      
      return SUCCESS;
      
  }
 /***************************************************************************
 * Start the component. Start the clock.
 *
 ***************************************************************************/
  command result_t StdControl.start()
  {

#if FEATURE_UART_SEND
      // Set baud rate to one that has low error with internal oscillator.
	  // Must be set in HPLUART0M...
	  //outp(0,  UBRR0H); 
	  //outp(51, UBRR0L);  // 19.6K,  0.2% error
	  //outp(25, UBRR0L);  // 38.4K,  0.2% error
#endif
  	

#ifdef MTS310
      call AccelControl.start();
      call MagControl.start();
#endif

      call Timer.start(TIMER_REPEAT, timer_rate);
      return SUCCESS;	
  }

/***************************************************************************
 * Stop the component.
 *
 ***************************************************************************/
  command result_t StdControl.stop() {
      call BattControl.stop(); 
      call TempControl.stop();  
      call PhotoControl.stop(); 
#ifdef MTS310
      call AccelControl.stop();
      call MagControl.stop();
#endif 

      return SUCCESS;
  }
/****************************************************************************
 * Measure Temp, Light, Mic, toggle sounder  
 *
 ****************************************************************************/
  event result_t Timer.fired() {
      char l_state;

      atomic l_state = main_state;

      call Leds.greenToggle();

      if (sending_packet) 
	  return SUCCESS;             //don't overrun buffers

      l_state = START;

      switch (l_state) {
	  case SOUND_DONE:
	      atomic main_state = START;
	      break;

	  case START:
	      atomic main_state = BUSY;
	      call BattControl.start(); 
	      call ADCBATT.getData();     //get sensor data;
	      break;

	  case BUSY:
	  	break;
	  default:
	      break;
      }

      return SUCCESS;
  }
  
 /***************************************************************************
 * Battery Ref  or thermistor data ready 
 ***************************************************************************/
  async event result_t ADCBATT.dataReady(uint16_t data) {
      readings.vref = data;
      call BattControl.stop(); 
      call TempControl.start();   
      call Temperature.getData(); 
      return SUCCESS;
  }
    
/***************************************************************************
 * Temperature ADC data ready 
 * Read and get next channel.
 **************************************************************************/ 
  async event result_t Temperature.dataReady(uint16_t data) {
      readings.thermistor = data;
      call TempControl.stop();
      call PhotoControl.start();  
      call Light.getData(); 
      return SUCCESS;
  }

/***************************************************************************
 * Photocell ADC data ready 
 * Read and get next channel.
 **************************************************************************/ 
  async event result_t Light.dataReady(uint16_t data) {
      readings.light = data;
      call PhotoControl.stop();    
 	  call MicControl.start(); 
      call MicADC.getData();   
      return SUCCESS;
  }

/***************************************************************************
 * MicroPhone ADC data ready 
 * Read and toggle sounder.
 * send uart packet
 **************************************************************************/
  async event result_t MicADC.dataReady(uint16_t data) {
     readings.mic = data;

#ifdef MTS310
     call AccelX.getData();
#else      
     // This is the final sensor reading for the MTS300...
     atomic {
	 if (!sending_packet) {
	     sending_packet = TRUE;
	     post send_radio_msg();
	 }
     }
     
#if FEATURE_SOUNDER
     if (sound_state) call Sounder.start();
     else call Sounder.stop();
     atomic {
	 sound_state = SOUND_STATE_CHANGE;
	 atomic main_state = SOUND_DONE;
     }
#endif
#endif
     return SUCCESS;
 } 
  
 
/***************************************************************************
 *  ADC data ready 
 * Read and toggle sounder.
 * send uart packet
 ***************************************************************************/
  async event result_t AccelX.dataReady(uint16_t data) {
      readings.accelX = data;

      call AccelY.getData();   
      return SUCCESS;
  }

/***************************************************************************
 *  ADC data ready 
 * Read and toggle sounder.
 * send uart packet
 ***************************************************************************/
  async event result_t AccelY.dataReady(uint16_t data) {
      readings.accelY = data;

      call MagX.getData();
      return SUCCESS;
  }

 /**
  * In response to the <code>MagX.dataReady</code> event, it stores the 
  * sample and issues command to sample the magnetometer's Y axis. 
  * (Magnetometer B pin)
  *  
  * @return returns <code>SUCCESS</code>
  */
  async event result_t MagX.dataReady(uint16_t data){
      readings.magX = data;

      call  MagY.getData(); //get data for MagnetometerB
      return SUCCESS;  
  }

 /**
  * In response to the <code>MagY.dataReady</code> event, it stores the 
  * sample and issues a task to filter and process the stored magnetometer 
  * data.
  *
  * It also has a schedule which starts sampling the Temperture and 
  * Accelormeter depending on the stepdown counter.
  * 
  * @return returns <code>SUCCESS</code>
  */
  async event result_t MagY.dataReady(uint16_t data){
      readings.magY = data;	  
	
      atomic {
	  if (!sending_packet) {
	      sending_packet = TRUE;
	      post send_radio_msg();
	  }
      }
      
#if FEATURE_SOUNDER
      if (sound_state) call Sounder.start();
      else call Sounder.stop();
      atomic {
	  sound_state = SOUND_STATE_CHANGE;
	  atomic main_state = SOUND_DONE;
      }
#endif
      return SUCCESS;  
  }

 /** 
  * Handles all broadcast command messages sent over network. 
  *
  * NOTE: Bcast messages will not be received if seq_no is not properly
  *       set in first two bytes of data payload.  Also, payload is 
  *       the remaining data after the required seq_no.
  *
  * @version   2004/10/5   mturon     Initial version
  */
  event result_t XCommand.received(XCommandOp *opcode) {

      switch (opcode->cmd) {
	  case XCOMMAND_SET_RATE:
	      // Change the data collection rate.
	      timer_rate = opcode->param.newrate;
	      call Timer.stop();
	      call Timer.start(TIMER_REPEAT, timer_rate);
	      break;
	      
	  case XCOMMAND_SLEEP:
	      // Stop collecting data, and go to sleep.
	      sleeping = TRUE;
	      call Timer.stop();
	      call Leds.set(0);
              break;
	      
	  case XCOMMAND_WAKEUP:
	      // Wake up from sleep state.
	      if (sleeping) {
		  initialize();
		  call Timer.start(TIMER_REPEAT, timer_rate);
		  sleeping = FALSE;
	      }
	      break;
	      
	  case XCOMMAND_RESET:
	      // Reset the mote now.
	      break;

	  case XCOMMAND_ACTUATE: {
	      uint16_t state = opcode->param.actuate.state;
	      if (opcode->param.actuate.device != XCMD_DEVICE_SOUNDER) break;
	      
	      // Play the sounder for one period.
	      sound_state = state;
	      if (sound_state) call Sounder.start();
	      else call Sounder.stop();
	      atomic {
		  sound_state = SOUND_STATE_CHANGE;
		  atomic main_state = SOUND_DONE;
	      }
	      break;
	  }
	      

	  default:
	      break;
      }    
      
      return SUCCESS;
  }
  
#if FEATURE_UART_SEND
 /**
  * Handle completion of sent UART packet.
  *
  * @author    Martin Turon
  * @version   2004/7/21      mturon       Initial revision
  */
  event result_t SendUART.sendDone(TOS_MsgPtr msg, result_t success) 
  {
      //      if (msg->addr == TOS_UART_ADDR) {
      atomic msg_radio = msg;
      msg_radio->addr = TOS_BCAST_ADDR;
      
      if (call Send.send(msg_radio, sizeof(XDataMsg)) != SUCCESS) {
	  atomic sending_packet = FALSE;
	  call Leds.yellowOff();
      }
      
      if (TOS_LOCAL_ADDRESS != 0) // never turn on power mgr for base
	  call PowerMgrEnable();
      
      //}
      return SUCCESS;
  }
#endif

 /**
  * Handle completion of sent RF packet.
  *
  * @author    Martin Turon
  * @version   2004/5/27      mturon       Initial revision
  */
  event result_t Send.sendDone(TOS_MsgPtr msg, result_t success) 
  {
      atomic {
	  msg_radio = msg;
	  main_state = START;
	  sending_packet = FALSE;
      }
      call Leds.yellowOff();
      
#if FEATURE_UART_SEND
      if (TOS_LOCAL_ADDRESS != 0) // never turn on power mgr for base
	  call PowerMgrEnable();
#endif
      
      return SUCCESS;
  }
  
#ifdef XMESHSYNC  
  task void SendPing() {
    XDataMsg *pReading;
    uint16_t Len;

      
    if ((pReading = (XDataMsg *)call Send.getBuffer(msg_radio,&Len))) {
      pReading->parent = call RouteControl.getParent();
      if ((call Send.send(msg_radio,sizeof(XDataMsg))) != SUCCESS)
	atomic sending_packet = FALSE;
    }

  }


    event TOS_MsgPtr DownTree.receive(TOS_MsgPtr pMsg, void* payload, uint16_t payloadLen) {

        if (!sending_packet) {
	   call Leds.yellowToggle();
	   atomic sending_packet = TRUE;
           post SendPing();  //  pMsg->XXX);
        }
	return pMsg;
  }
#endif  

}



