/*									tab:4
 *
 * "Copyright (c) 2000-2002 The Regents of the University  of California.  
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
 */
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
 */
/*
 * Copyright (c) 2002, Vanderbilt University
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE VANDERBILT UNIVERSITY BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE VANDERBILT
 * UNIVERSITY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE VANDERBILT UNIVERSITY SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE VANDERBILT UNIVERSITY HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS.
 */

/* History:   created 1/25/2001

 - captures all the packets that it can hear and report it back to the UART
 - forward all incoming UART messages out to the radio
 - added buffering (Miklos Maroti, 4/10/2003)
*/

includes MsgList;
	
module GenericBaseM {
	provides interface StdControl;
	uses {
		interface StdControl as UARTControl;
		interface BareSendMsg as UARTSend;
		interface ReceiveMsg as UARTReceive;

		interface StdControl as RadioControl;
		interface BareSendMsg as RadioSend;
		interface ReceiveMsg as RadioReceive;

		interface MsgList;

		interface Leds;
	}
}

implementation
{
	TOS_Msg buffer[70];

	TOS_MsgList free;
	TOS_MsgList toUart;
	TOS_MsgList toRadio;

	command result_t StdControl.init() {
		call MsgList.init(&free);
		call MsgList.init(&toUart);
		call MsgList.init(&toRadio);
		call MsgList.addAll(&free, buffer, 30);

		call UARTControl.init();
		call RadioControl.init();
		call Leds.init();

		return SUCCESS;
	}

	command result_t StdControl.start() {
		call UARTControl.start();
		call RadioControl.start();

		return SUCCESS;
	}

	command result_t StdControl.stop() {
		call UARTControl.stop();
		call RadioControl.stop();

		return SUCCESS;
	}

	task void sendToUart()
	{
		 TOS_MsgPtr msg;

		 if( call MsgList.isEmpty(&toUart) )
			 return;

		 msg = call MsgList.removeFirst(&toUart);
		 msg->addr = TOS_UART_ADDR;	// need to change it, unfortunately
		 if( call UARTSend.send(msg) != SUCCESS )
			 call MsgList.addFirst(&toUart, msg);
	}	
	
	task void sendToRadio()
	{
		 TOS_MsgPtr msg;

		 if( call MsgList.isEmpty(&toRadio) )
			 return;

		 msg = call MsgList.removeFirst(&toRadio);
		 if( call RadioSend.send(msg) != SUCCESS )
			 call MsgList.addFirst(&toRadio, msg);
	}	
	
	event result_t UARTSend.sendDone(TOS_MsgPtr msg, result_t success) {
		call MsgList.addLast(&free, msg);

		if( ! call MsgList.isEmpty(&toUart) )
			post sendToUart();

		return SUCCESS;
	}
	
	event result_t RadioSend.sendDone(TOS_MsgPtr msg, result_t success) {
		call MsgList.addFirst(&free, msg);

		if( ! call MsgList.isEmpty(&toRadio) )
			post sendToRadio();

		return SUCCESS;
	}

	event TOS_MsgPtr RadioReceive.receive(TOS_MsgPtr data) {
		if ( !data->crc || data->group != TOS_AM_GROUP ) {
			return data;
		}
		if ( call MsgList.isEmpty(&free) ) {
			call Leds.yellowToggle();
			return data;
		}
		call Leds.greenToggle();

		call MsgList.addLast(&toUart, data);
		post sendToUart();

		return call MsgList.removeFirst(&free);
	}
	
	event TOS_MsgPtr UARTReceive.receive(TOS_MsgPtr data) {
		TOS_MsgPtr ret;

		if ( call MsgList.isEmpty(&free) ) {
			call Leds.yellowToggle();

			// try stealing one from the incoming queue
			if( ! call MsgList.isEmpty(&toUart) )
				ret = call MsgList.removeFirst(&toUart);
			else
				return data;
		}
		else
			ret = call MsgList.removeFirst(&free);

		call Leds.redToggle();

		if( data->group != TOS_AM_GROUP ) {
			data->group = TOS_AM_GROUP;
			call Leds.yellowToggle();
		}

		call MsgList.addLast(&toRadio, data);
		post sendToRadio();

		return ret;
	}
}	
