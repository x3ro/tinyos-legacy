/*
 * Copyright (c) 2003, Vanderbilt University
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
 *
 * Author: Peter Volgyesi
 * Date last modified: 6/2/2003 7:40PM
 */

includes StackMsg;

module TestPeaceKeeperM
{
	provides
	{
		interface StdControl;
	}
	uses
	{
		interface PeaceKeeper;
		interface StdControl as CommControl;
		interface SendMsg as SendStackMsg;
	}
}

implementation
{
	TOS_Msg msg;
	
	// Uncomment the following line to see what happens if the memory is not enough for data+stack+DMZ
	// uint8_t	buff[RAMEND-300];
	uint8_t	buff[RAMEND-800];
	
	
	void send_debug()
	{
		struct StackMsg *stack_msg;
		stack_msg = (struct StackMsg*)(msg.data);
		stack_msg->max_stack_size = call PeaceKeeper.getMaxStack();
		call SendStackMsg.send(TOS_UART_ADDR, sizeof(struct StackMsg), &msg);
	}
	
	command result_t StdControl.init() 
	{
		unsigned int i;
		for (i=0; i < sizeof(buff); i++)
		{
			buff[i] = 0;
		}
		call CommControl.init();
		return SUCCESS;
	}

	
	command result_t StdControl.start()
	{
		// Uncomment the following line to see what happens if stack access destroys the DMZ
		// uint8_t	local_buff[200];
		
		call CommControl.start();
		
		// Uncomment the following line to see what happens if an invalid pointer destroys the DMZ
		// *((&__bss_end)+1) = 0;
		
		send_debug();
		
		return SUCCESS;
	}

	command result_t StdControl.stop() 
	{
		call CommControl.stop();
		return SUCCESS;
	}
	
	event result_t SendStackMsg.sendDone(TOS_MsgPtr sent, result_t success) {
		send_debug();
    		return SUCCESS;
  	}  
	
	
}
