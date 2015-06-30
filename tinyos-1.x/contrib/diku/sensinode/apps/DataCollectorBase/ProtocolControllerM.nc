/* Copyright (c) 2006, Marcus Chang, Klaus Madsen
         All rights reserved.

         Redistribution and use in source and binary forms, with or without 
         modification, are permitted provided that the following conditions are met:

         * Redistributions of source code must retain the above copyright notice, 
         this list of conditions and the following disclaimer. 

         * Redistributions in binary form must reproduce the above copyright notice,
         this list of conditions and the following disclaimer in the documentation 
         and/or other materials provided with the distribution. 

         * Neither the name of the Dept. of Computer Science, University of 
         Copenhagen nor the names of its contributors may be used to endorse or 
         promote products derived from this software without specific prior 
         written permission. 

         THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" 
         AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE 
         IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE 
         ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE 
         LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR 
         CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF 
         SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS 
         INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN 
         CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) 
         ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE 
         POSSIBILITY OF SUCH DAMAGE.
*/      

/*
        Author:         Marcus Chang <marcus@diku.dk>
        Klaus S. Madsen <klaussm@diku.dk>
        Last modified:  March, 2007
*/


module ProtocolControllerM {
	provides {
		interface StdControl;
	}

	uses {
		interface StdControl as ProtocolControl;
		interface UARTFrame;
		interface Timer;
		interface Leds;
	}
}

implementation {

#define UART_TIME_INTERVAL 20000

	bool linkAlive = FALSE, radioOn = FALSE;
    uint8_t send[4];

	command result_t StdControl.init() {
				
		call ProtocolControl.init();
		call Leds.init();

        /* header */
        send[0] = 1 + 2;
        send[1] = UART_FRAME_ALIVE;
	
		return SUCCESS;
	}

	command result_t StdControl.start() 
	{
		return SUCCESS;
	}

	command result_t StdControl.stop() 
	{
		return SUCCESS;
	}

	/**************************************************************************
	** UARTFrame
	**************************************************************************/
	event void UARTFrame.sendFrameDone(uint8_t * frame)
	{
		if ( (frame[0] > 0) && (frame[1] == UART_FRAME_FRAGMENT) )
			linkAlive = TRUE;

		call Leds.redToggle();
	}

	event void UARTFrame.receivedFrame(uint8_t * frame)
	{
		if (frame[0] > 0) 
		{
			switch(frame[1]) {
				case UART_FRAME_ALIVE:
					if (!linkAlive)
					{
						linkAlive = TRUE;
						
						if (!radioOn)
						{
							radioOn = TRUE;
							call ProtocolControl.start();
							call Timer.start(TIMER_ONE_SHOT, UART_TIME_INTERVAL);
						}

						call Leds.redOff();
						call Leds.greenOn();
					}
				default:
					linkAlive = TRUE;
					break;
			}
		}
	}

	/**************************************************************************
	** Timer
	**************************************************************************/
	event result_t Timer.fired()
	{
		if (linkAlive) {
			linkAlive = FALSE;
			call Timer.start(TIMER_ONE_SHOT, UART_TIME_INTERVAL);
		} else {
			radioOn = FALSE;
			call ProtocolControl.stop();
			call Leds.redOff();
			call Leds.greenOff();
		}

        /* send alive heartbeat to PC */
        call UARTFrame.sendFrame(send);

		return SUCCESS;
	}
	
}
