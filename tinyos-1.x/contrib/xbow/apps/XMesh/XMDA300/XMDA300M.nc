/*									tab:4
 *  IMPORTANT: READ BEFORE DOWNLOADING, COPYING, INSTALLING OR USING.  By
 *  downloading, copying, installing or using the software you agree to
 *  this license.  If you do not agree to this license, do not download,
 *  install, copy or use the software.
 *
 *  Intel Open Source License 
 *
 *  Copyright (c) 2002 Intel Corporation 
 *  All rights reserved. 
 *  Redistribution and use in source and binary forms, with or without
 *  modification, are permitted provided that the following conditions are
 *  met:
 * 
 *	Redistributions of source code must retain the above copyright
 *  notice, this list of conditions and the following disclaimer.
 *	Redistributions in binary form must reproduce the above copyright
 *  notice, this list of conditions and the following disclaimer in the
 *  documentation and/or other materials provided with the distribution.
 *      Neither the name of the Intel Corporation nor the names of its
 *  contributors may be used to endorse or promote products derived from
 *  this software without specific prior written permission.
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
 *  @author Leah Fera, Martin Turon, Jaidev Prabhu
 *
 *  $Id: XMDA300M.nc,v 1.4 2005/01/11 05:21:35 husq Exp $ 
 */


/******************************************************************************
 *
 *    - Tests the MDA300 general prototyping card 
 *       (see Crossbow MTS Series User Manual)
 *    -  Read and control all MDA300 signals:
 *      ADC0, ADC1, ADC2, ADC3,...ADC11 inputs, DIO 0-5, 
 *      counter, battery, humidity, temp
 *-----------------------------------------------------------------------------
 * Output results through mica2 uart and radio. 
 * Use xlisten.exe program to view data from either port:
 *  uart: mount mica2 on mib510 with MDA300 
 *              (must be connected or now data is read)
 *        connect serial cable to PC
 *        run xlisten.exe at 57600 baud
 *  radio: run mica2 with MDA300, 
 *         run another mica2 with TOSBASE
 *         run xlisten.exe at 56K baud
 * LED: the led will be green if the MDA300 is connected to the mica2 and 
 *      the program is running (and sending out packets).  Otherwise it is red.
 *-----------------------------------------------------------------------------
 * Data packet structure:
 * 
 * PACKET #1 (of 4)
 * ----------------
 *  msg->data[0] : sensor id, MDA300 = 0x81
 *  msg->data[1] : packet number = 1
 *  msg->data[2] : node id
 *  msg->data[3] : reserved
 *  msg->data[4,5] : analog adc data Ch.0
 *  msg->data[6,7] : analog adc data Ch.1
 *  msg->data[8,9] : analog adc data Ch.2
 *  msg->data[10,11] : analog adc data Ch.3
 *  msg->data[12,13] : analog adc data Ch.4
 *  msg->data[14,15] : analog adc data Ch.5
 *  msg->data[16,17] : analog adc data Ch.6
 * 
 * PACKET #2 (of 4)
 * ----------------
 *  msg->data[0] : sensor id, MDA300 = 0x81
 *  msg->data[1] : packet number = 2
 *  msg->data[2] : node id
 *  msg->data[3] : reserved
 *  msg->data[4,5] : analog adc data Ch.7
 *  msg->data[6,7] : analog adc data Ch.8
 *  msg->data[8,9] : analog adc data Ch.9
 *  msg->data[10,11] : analog adc data Ch.10
 *  msg->data[12,13] : analog adc data Ch.11
 *  msg->data[14,15] : analog adc data Ch.12
 *  msg->data[16,17] : analog adc data Ch.13
 *
 * 
 * PACKET #3 (of 4)
 * ----------------
 *  msg->data[0] : sensor id, MDA300 = 0x81
 *  msg->data[1] : packet number = 3
 *  msg->data[2] : node id
 *  msg->data[3] : reserved
 *  msg->data[4,5] : digital data Ch.0
 *  msg->data[6,7] : digital data Ch.1
 *  msg->data[8,9] : digital data Ch.2
 *  msg->data[10,11] : digital data Ch.3
 *  msg->data[12,13] : digital data Ch.4
 *  msg->data[14,15] : digital data Ch.5
 *
 * PACKET #4 (of 4)
 * ----------------
 *  msg->data[0] : sensor id, MDA300 = 0x81
 *  msg->data[1] : packet number = 4
 *  msg->data[2] : node id
 *  msg->data[3] : reserved
 *  msg->data[4,5] : batt
 *  msg->data[6,7] : hum
 *  msg->data[8,9] : temp
 *  msg->data[10,11] : counter
 *  msg->data[14] : msg4_status (debug)
 * 
 ***************************************************************************/

// include sensorboard.h definitions from tos/mda300 directory
#include "appFeatures.h"
includes XCommand;


includes sensorboard;
module XMDA300M
{
  
    provides interface StdControl;
  
    uses {
	interface Leds;

	interface Send;
	interface RouteControl;
#ifdef XMESHSYNC
    interface Receive as DownTree; 	
#endif  		
	interface XCommand;

	//Sampler Communication
	interface StdControl as SamplerControl;
	interface Sample;

    
	//Timer
	interface Timer;
    
	//relays
	interface Relay as relay_normally_closed;
	interface Relay as relay_normally_open;   
    
	//support for plug and play
	command result_t PlugPlay();

#if FEATURE_UART_SEND
	interface SendMsg as SendUART;
	command result_t PowerMgrEnable();
	command result_t PowerMgrDisable();
#endif
    }
}


implementation
{ 	
#define ANALOG_SAMPLING_TIME    90
#define DIGITAL_SAMPLING_TIME  100
#define MISC_SAMPLING_TIME     110

#define ANALOG_SEND_FLAG  1
#define DIGITAL_SEND_FLAG 1
#define MISC_SEND_FLAG    1
#define ERR_SEND_FLAG     1

#define PACKET_FULL	0x1FF

#define MSG_LEN  29   // excludes TOS header, but includes xbow header
    
    enum {
	PENDING = 0,
	NO_MSG = 1
    };        

    enum {
	MDA300_PACKET1 = 1,
	MDA300_PACKET2 = 2,
	MDA300_PACKET3 = 3,
	MDA300_PACKET4 = 4,
	MDA300_ERR_PACKET = 0xf8	
    };

/******************************************************
    enum {
	SENSOR_ID = 0,
	PACKET_ID, 
	NODE_ID,
	RESERVED,
	DATA_START
    } XPacketDataEnum;
******************************************************/	
    /* Messages Buffers */	
    uint32_t   timer_rate;  
    bool       sleeping;	       // application command state
    bool sending_packet;
    uint16_t    seqno;
	XDataMsg  *tmppack;

    TOS_Msg packet;
    TOS_Msg msg_send_buffer;    
    TOS_MsgPtr msg_ptr;
    


    uint16_t msg_status, pkt_full;
    char test;

    int8_t record[25];

  static void initialize() 
    {
      atomic 
      {
    	  sleeping = FALSE;
    	  sending_packet = FALSE;
    	  timer_rate = XSENSOR_SAMPLE_RATE;
      }
    }
 
/****************************************************************************
 * Initialize the component. Initialize Leds
 *
 ****************************************************************************/
    command result_t StdControl.init() {
        
    uint8_t i;

	call Leds.init();
        
	atomic {
	    msg_ptr = &msg_send_buffer;
	    //sending_packet = FALSE;
	}
    msg_status = 0;
	pkt_full = PACKET_FULL;

    MAKE_BAT_MONITOR_OUTPUT();  // enable voltage ref power pin as output
    MAKE_ADC_INPUT();           // enable ADC7 as input
      
// usart1 is also connected to external serial flash
// set usart1 lines to correct state
//  TOSH_MAKE_FLASH_SELECT_OUTPUT();
    TOSH_MAKE_FLASH_OUT_OUTPUT();             //tx output
    TOSH_MAKE_FLASH_CLK_OUTPUT();             //usart clk
//  TOSH_SET_FLASH_SELECT_PIN();

    call SamplerControl.init();
    initialize();
    return SUCCESS;
            
	//return rcombine(call SamplerControl.init(), call CommControl.init());
    }


 
/****************************************************************************
 * Start the component. Start the clock. Setup timer and sampling
 *
 ****************************************************************************/
    command result_t StdControl.start() {

        
	call SamplerControl.start();
        

    
	if(call PlugPlay())
	{
            
	    call Timer.start(TIMER_REPEAT, timer_rate);
            
            
	    //channel parameteres are irrelevent
            
	    record[14] = call Sample.getSample(0,TEMPERATURE,MISC_SAMPLING_TIME,SAMPLER_DEFAULT);
            
	    record[15] = call Sample.getSample(0,HUMIDITY,MISC_SAMPLING_TIME,SAMPLER_DEFAULT);
            
	    record[16] = call Sample.getSample(0, BATTERY,MISC_SAMPLING_TIME,SAMPLER_DEFAULT);

            
	    //start sampling  channels. Channels 7-10 with averaging since they are more percise.channels 3-6 make active excitation    
	    record[0] = call Sample.getSample(0,ANALOG,ANALOG_SAMPLING_TIME,SAMPLER_DEFAULT | EXCITATION_33);

	    record[1] = call Sample.getSample(1,ANALOG,ANALOG_SAMPLING_TIME,SAMPLER_DEFAULT );
            
	    record[2] = call Sample.getSample(2,ANALOG,ANALOG_SAMPLING_TIME,SAMPLER_DEFAULT);
            
	    record[3] = call Sample.getSample(3,ANALOG,ANALOG_SAMPLING_TIME,SAMPLER_DEFAULT | EXCITATION_33 | DELAY_BEFORE_MEASUREMENT);
            
	    record[4] = call Sample.getSample(4,ANALOG,ANALOG_SAMPLING_TIME,SAMPLER_DEFAULT);
            
	    record[5] = call Sample.getSample(5,ANALOG,ANALOG_SAMPLING_TIME,SAMPLER_DEFAULT);
            
	    record[6] = call Sample.getSample(6,ANALOG,ANALOG_SAMPLING_TIME,SAMPLER_DEFAULT);
            
	    record[7] = call Sample.getSample(7,ANALOG,ANALOG_SAMPLING_TIME,AVERAGE_FOUR | EXCITATION_25);
            
	    record[8] = call Sample.getSample(8,ANALOG,ANALOG_SAMPLING_TIME,AVERAGE_FOUR | EXCITATION_25);
            
	    record[9] = call Sample.getSample(9,ANALOG,ANALOG_SAMPLING_TIME,AVERAGE_FOUR | EXCITATION_25);
            
	    record[10] = call Sample.getSample(10,ANALOG,ANALOG_SAMPLING_TIME,AVERAGE_FOUR | EXCITATION_25);
         
	    record[11] = call Sample.getSample(11,ANALOG,ANALOG_SAMPLING_TIME,SAMPLER_DEFAULT);
            
	    record[12] = call Sample.getSample(12,ANALOG,ANALOG_SAMPLING_TIME,SAMPLER_DEFAULT);
            
	    record[13] = call Sample.getSample(13,ANALOG,ANALOG_SAMPLING_TIME,SAMPLER_DEFAULT | EXCITATION_50 | EXCITATION_ALWAYS_ON);                                
                        
            
	    //digital chennels as accumulative counter                
            
	    record[17] = call Sample.getSample(0,DIGITAL,DIGITAL_SAMPLING_TIME,RESET_ZERO_AFTER_READ | FALLING_EDGE);
            
	    record[18] = call Sample.getSample(1,DIGITAL,DIGITAL_SAMPLING_TIME,RISING_EDGE | EVENT);
            
	    record[19] = call Sample.getSample(2,DIGITAL,DIGITAL_SAMPLING_TIME,SAMPLER_DEFAULT | EVENT);
            
	    record[20] = call Sample.getSample(3,DIGITAL,DIGITAL_SAMPLING_TIME,FALLING_EDGE);
            
	    record[21] = call Sample.getSample(4,DIGITAL,DIGITAL_SAMPLING_TIME,RISING_EDGE);
            
	    record[22] = call Sample.getSample(5,DIGITAL,DIGITAL_SAMPLING_TIME,RISING_EDGE | EEPROM_TOTALIZER);                                
            
	    //counter channels for frequency measurement, will reset to zero.
            
	    record[23] = call Sample.getSample(0, COUNTER,MISC_SAMPLING_TIME,RESET_ZERO_AFTER_READ | RISING_EDGE);
	    call Leds.greenOn();          
	}
        
	else {
	    call Leds.redOn();
	}
        
	return SUCCESS;
    
    }
    
/****************************************************************************
 * Stop the component.
 *
 ****************************************************************************/
 
    command result_t StdControl.stop() {
        
 	call SamplerControl.stop();
    
 	return SUCCESS;
    
    }




/****************************************************************************
 * Task to transmit radio message
 * NOTE that data payload was already copied from the corresponding UART packet
 ****************************************************************************/
    task void send_radio_msg() 
	{
	    uint8_t i;
        uint16_t  len;
	    XDataMsg *data;
	    if(sending_packet)
          return;
        atomic sending_packet=TRUE;
	// Fill the given data buffer.	
    	data = (XDataMsg*)call Send.getBuffer(msg_ptr, &len);
        tmppack=(XDataMsg *)packet.data;  
    	for (i = 0; i <= sizeof(XDataMsg)-1; i++) 
    	    ((uint8_t*)data)[i] = ((uint8_t*)tmppack)[i];

        data->xmeshHeader.packet_id = 6;
    	data->xmeshHeader.board_id  = SENSOR_BOARD_ID;
    	data->xmeshHeader.node_id   = TOS_LOCAL_ADDRESS;
    	data->xmeshHeader.parent    = call RouteControl.getParent();



    #if FEATURE_UART_SEND
    	if (TOS_LOCAL_ADDRESS != 0) {
    		call Leds.yellowOn();
    	    call PowerMgrDisable();
    	    TOSH_uwait(1000);
    	    if (call SendUART.send(TOS_UART_ADDR, sizeof(XDataMsg),msg_ptr) != SUCCESS) 
    	    {
    		atomic sending_packet = FALSE;
    		call Leds.greenToggle();
    		call PowerMgrEnable();
    	    }
    	} 
    	else 
    #endif
    	{
    	    // Send the RF packet!
    		call Leds.yellowOn();
    	    if (call Send.send(msg_ptr, sizeof(XDataMsg)) != SUCCESS) {
    		atomic sending_packet = FALSE;
    		call Leds.yellowOn();
    		call Leds.greenOff();
    	    }
    	}

        

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
      atomic msg_ptr = msg;
      msg_ptr->addr = TOS_BCAST_ADDR;
      
      if (call Send.send(msg_ptr, sizeof(XDataMsg)) != SUCCESS) {
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
	  msg_ptr = msg;
	  sending_packet = FALSE;
      }
      call Leds.yellowOff();
      
#if FEATURE_UART_SEND
      if (TOS_LOCAL_ADDRESS != 0) // never turn on power mgr for base
	  call PowerMgrEnable();
#endif
      
      return SUCCESS;
  }
 
/**
 * Handle a single dataReady event for all MDA300 data types. 
 * 
 * @author    Leah Fera, Martin Turon
 *
 * @version   2004/3/17       leahfera    Intial revision
 * @n         2004/4/1        mturon      Improved state machine
 */
    event result_t 
	Sample.dataReady(uint8_t channel,uint8_t channelType,uint16_t data)
	{          
	    uint8_t i;

	    switch (channelType) {
		case ANALOG:              
		    switch (channel) {		  
			// MSG 1 : first part of analog channels (0-6)
			case 0:
                tmppack=(XDataMsg *)packet.data;
			    tmppack->xData.datap6.adc0 =data ;
			    atomic {msg_status|=0x01;}
			    break;

			case 1:   
                tmppack=(XDataMsg *)packet.data;
			    tmppack->xData.datap6.adc1 =data ;
			    atomic {msg_status|=0x02;}
			    break;
             
			case 2:
                tmppack=(XDataMsg *)packet.data;
			    tmppack->xData.datap6.adc2 =data ;
			    atomic {msg_status|=0x04;}
			    break;
              
              
              
			default:
			    break;
		    }  // case ANALOG (channel) 
		    break;
          
		case DIGITAL:
		    switch (channel) {             
			case 0:
                tmppack=(XDataMsg *)packet.data;

			    tmppack->xData.datap6.dig0=data;
			    atomic {msg_status|=0x08;}
			    break;
              
			case 1:
                tmppack=(XDataMsg *)packet.data;
			    tmppack->xData.datap6.dig1=data;
			    atomic {msg_status|=0x10;}
			    break;
            
			case 2:
                tmppack=(XDataMsg *)packet.data;
			    tmppack->xData.datap6.dig2=data;
			    atomic {msg_status|=0x20;}
			    break;
              
              
			default:
			    break;
		    }  // case DIGITAL (channel)
		    break;

		case BATTERY:            
            tmppack=(XDataMsg *)packet.data;
			tmppack->xData.datap6.vref =data ;
		    atomic {msg_status|=0x40;}
		    break;
          
		case HUMIDITY:            
            tmppack=(XDataMsg *)packet.data;
			tmppack->xData.datap6.humid =data ;
		    atomic {msg_status|=0x80;}
		    break;
                    
		case TEMPERATURE:          
            tmppack=(XDataMsg *)packet.data;
			tmppack->xData.datap6.humtemp =data ;
		    atomic {msg_status|=0x100;}
		    break;


		default:
		    break;

	    }  // switch (channelType) 

        if (sending_packet)
             return SUCCESS; 
            
		if (msg_status == pkt_full) {
		 msg_status = 0;
		 post send_radio_msg();
		} 
          
	    return SUCCESS;      
	}
  
/****************************************************************************
 * Timer Fired - 
 *
 ****************************************************************************/
    event result_t Timer.fired() {
      if (sending_packet) 
	  return SUCCESS;             //don't overrun buffers
 	if (test != 0)  {
	    test=0;
	    call relay_normally_closed.toggle();
        call Leds.greenOn();
 	}
	else  {
	    test=1;
	    call relay_normally_open.toggle();
        call Leds.greenOn();
 	}

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

	  case XCOMMAND_ACTUATE:
	      break;	      

	  default:
	      break;
      }    
      
      return SUCCESS;
  }

#ifdef XMESHSYNC  
  task void SendPing() {
    XDataMsg *pReading;
    uint16_t Len;

      
    if ((pReading = (XDataMsg *)call Send.getBuffer(msg_ptr,&Len))) {
      pReading->xmeshHeader.parent = call RouteControl.getParent();
      if ((call Send.send(msg_ptr,sizeof(XDataMsg))) != SUCCESS)
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
