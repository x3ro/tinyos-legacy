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
 *  $Id: XSensorMDA300M.nc,v 1.6 2004/09/09 21:59:28 jdprabhu Exp $ 
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
 *  msg->data[10,11] : battery
 *  msg->data[12,13] : humidity
 *  msg->data[14,15] : temperature
 * 
 ***************************************************************************/

#include "appFeatures.h"

// include sensorboard.h definitions from tos/mda300 directory
includes sensorboard;

module XSensorMDA300M
{
  
    provides {
	interface StdControl;
    }
  
    uses {
	interface Leds;
	// interface Timer;

	//RF communication
	interface Send;
	interface RouteControl;
    
	//Sampler Communication
	interface StdControl as SamplerControl;
	interface Sample;

    }
}


implementation
{ 	
#define PACKET_FULL	0x3F

#define MSG_LEN  29   // excludes TOS header, but includes xbow header
    
	
    /* Messages Buffers */	
    TOS_Msg radio_send_buffer;    
    TOS_MsgPtr radio_msg_ptr;
    uint16_t msg_len;
    
    bool    sending_packet;
    uint8_t msg_status;

    int8_t record[25];
    
    norace XDataMsg readings;

 
/****************************************************************************
 * Initialize the component. Initialize Leds
 *
 ****************************************************************************/
    command result_t StdControl.init() {
        
	atomic {
	    sending_packet = FALSE;
	    radio_msg_ptr = &radio_send_buffer;
	}
        
	call Leds.init();
	call SamplerControl.init(); 

	return SUCCESS; 
    }

/****************************************************************************
 * Start the component. Start the clock. Setup timer and sampling
 *
 ****************************************************************************/
    command result_t StdControl.start() {
        
	call SamplerControl.start();

        // Echo 10 Soil Moisture Probe
	record[0] = call Sample.getSample(0,
					  ANALOG,
					  XSENSOR_SAMPLE_RATE,
					  EXCITATION_25 | 
 					  DELAY_BEFORE_MEASUREMENT);

        // Echo 20 Soil Moisture Probe
	record[1] = call Sample.getSample(1,
					  ANALOG,
					  XSENSOR_SAMPLE_RATE,
					  EXCITATION_25 | 
					  DELAY_BEFORE_MEASUREMENT);
            		
        // Spectrum Soil Temperature Probe
	record[2] = call Sample.getSample(2,
					  ANALOG,
					  XSENSOR_SAMPLE_RATE,
					  EXCITATION_25);

	record[3] = call Sample.getSample(0,
					  TEMPERATURE,
					  XSENSOR_SAMPLE_RATE,
					  SAMPLER_DEFAULT);
            
	record[4] = call Sample.getSample(0,
					  HUMIDITY,
					  XSENSOR_SAMPLE_RATE,
					  SAMPLER_DEFAULT);
            
	record[5] = call Sample.getSample(0, 
					  BATTERY,
					  XSENSOR_SAMPLE_RATE,
					  SAMPLER_DEFAULT);

    return SUCCESS;
    
}
    
/****************************************************************************
 * Stop the component.
 ****************************************************************************/
 
    command result_t StdControl.stop() {
        
 	call SamplerControl.stop();
    
 	return SUCCESS;
    
    }


/****************************************************************************
 * Task to transmit radio message
 ****************************************************************************/
    task void send_radio_msg() 
	{
	    uint8_t i;
	    XDataMsg *data;

	    // Fill in the send buffer
	    data = (XDataMsg*)call Send.getBuffer(radio_msg_ptr, &msg_len);

	    for (i=0; i<= sizeof(XDataMsg)-1; i++)
		((uint8_t*) data)[i] = ((uint8_t*)&readings)[i];

	    data->board_id  = SENSOR_BOARD_ID;
	    data->node_id   = TOS_LOCAL_ADDRESS;
	    data->parent    = call RouteControl.getParent();
	    data->packet_id = 5;  // For Xlisten to decode properly    

	    call Leds.yellowOn();

	    // Send the RF packet!
	    if (call Send.send(radio_msg_ptr, msg_len) != SUCCESS) {
		atomic sending_packet = FALSE;
		call Leds.yellowOff();
	    }
	    
	}


/****************************************************************************
 * Radio msg xmitted. 
 ****************************************************************************/
    event result_t Send.sendDone(TOS_MsgPtr msg, result_t success) {
    
	atomic {
	    sending_packet = FALSE;
	}
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
	Sample.dataReady(uint8_t channel, uint8_t channelType, uint16_t data)
	{          
	    switch (channelType) {	

 		case ANALOG:              
		    switch (channel) {		  
			// MSG 1 : first part of analog channels (0-6)
			case 0:
			    readings.adc0 = data;
			    atomic {msg_status |= 0x01;}
			    break;

			case 1:   
			    readings.adc1 = data;
			    atomic {msg_status |= 0x02;}
			    break;
             
			case 2:
			    readings.adc2 = ((data & 0x0FF0) >> 4 );
			    atomic {msg_status |= 0x04;}
			    break;
              
			default:
			    break;
		    }  // case ANALOG (channel) 
		    break;
          
		case DIGITAL:
		    break;  // Don't care about Digital Channels

		case BATTERY:            
		    readings.vref = data;
		    atomic {msg_status |= 0x08;}

		    break;
          
		case HUMIDITY:            
		    readings.humid = data;
		    atomic {msg_status |= 0x10;}
		    break;
                    
		case TEMPERATURE:          
		    readings.humtemp = data;
		    atomic {msg_status |= 0x20;}
		    break;

		default:
		    break;

	    }  // switch (channelType) 

	    atomic {            
		if (!sending_packet && (msg_status == PACKET_FULL)) {
		    readings.seq_no++;
		    msg_status = 0;
		    post send_radio_msg();
		}
	    }

	    return SUCCESS;
	}
}
