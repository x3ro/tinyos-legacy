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
 * Author: Andras Nadas, Miklos Maroti
 * Contact: Janos Sallai (sallai@isis.vanderbilt.edu)
 * Date last modified: 02/02/05
 */



/**
 * The RadioCommandsM module implements IntCommand interfaces that allows
 * for changing the radio transmit strength on the MICA and MICA2
 * platforms, and changing the radio frequency on MICA2.
 *
 * @author Andras Nadas, Miklos Maroti
 * @modified 02/02/05
 */ 

module RadioCommandsM{
	provides{
		interface IntCommand as RadioCommand;
		interface IntCommand as RadioFreqCommand;
	}
	uses{

    // we support MICA2, MICA2DOT and MICA

#if defined(PLATFORM_MICA2) || defined(PLATFORM_MICA2DOT)
    // we need CC1000RadioC to set the transmit power/radio freq on
    // MICA2 and MICA2DOT
		interface CC1000Control;
		interface StdControl as CC1000StdControl;

    // we need a timer to defer sending the remote control response
    // after the radio frequency has been changed
		interface Timer;
#elif defined(PLATFORM_MICA)
    // we need PotC to set the transmit power on MICA
    // setting the freq on MICA is not supported
		interface Pot;
#endif
	}
}

implementation{
	uint8_t nextFreq;

    //***
    // IntCommand interface (aliased as RadioCommand)
    
    /**
     * Set the transmit power in a platform specific way.
     */
	command void RadioCommand.execute(uint16_t param){
#if defined(PLATFORM_MICA2) || defined(PLATFORM_MICA2DOT)
		signal RadioCommand.ack(call CC1000Control.SetRFPower(param));
#elif defined(PLATFORM_MICA)
		signal RadioCommand.ack(call Pot.init(param));
#endif
	}


    //***
    // IntCommand interface (aliased as RadioFreqCommand)
    
    /**
     * Handle the radio freq command for MICA2 and MICA2DOT, or return fail
     * for an unsupported platform.
     */
	command void RadioFreqCommand.execute(uint16_t param){
#if defined(PLATFORM_MICA2) || defined(PLATFORM_MICA2DOT)
		if (param<=8){
			nextFreq = param;
			// defer freq change - this node still has to participate in
			// the dissemination of this command, thus it has to operate on
			// the current radio freqency for a while (1 second)
			call Timer.start(TIMER_ONE_SHOT,1000);
		}
		signal RadioFreqCommand.ack(SUCCESS);
#else
		signal RadioFreqCommand.ack(FAIL);
#endif
	}


    /**
     * Execute the deferred frequency change request.
     */
#if defined(PLATFORM_MICA2) || defined(PLATFORM_MICA2DOT)
	task void switchRadio(){
		call CC1000StdControl.stop();
		call CC1000Control.TunePreset(nextFreq);
		call CC1000StdControl.start();
	}

    /**
     * Handles timer ticks and posts a task that execute the deferred
     * frequency change request.
     */
	event result_t Timer.fired(){
		post switchRadio();
		return SUCCESS;
	}
#endif
}
