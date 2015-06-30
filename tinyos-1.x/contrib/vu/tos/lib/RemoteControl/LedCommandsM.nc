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
 * Author: Andras Nadas, Miklos Maroti, Janos Sallai
 * Contact: Janos Sallai (sallai@isis.vanderbilt.edu)
 * Date last modified: 02/02/05
 */

/**
 * LedCommands allow for remotely set the LEDs via RemoteControl.
 * The acknowledgment value is the current LED setting.
 *
 * @author Andras Nadas, Miklos Maroti, Janos Sallai
 * @modified 02/02/05
 */ 


module LedCommandsM
{
	provides
	{
		interface IntCommand;
		interface StdControl;
	}
	uses
	{
		interface Leds;
	}
}

implementation
{

    //***
    // IntCommand interface
    
    /**
    * Execute the IntCommand.
    */
	command void IntCommand.execute(uint16_t param) 
	{
		if( param < 8 )
			call Leds.set(param);

		signal IntCommand.ack(call Leds.get());
	}


    //***
    // StdControl interface
    
    /**
    * We are initializing the Leds component here.
    */
    command result_t StdControl.init() { call Leds.init(); return SUCCESS; }

    /**
     * Do nothing here - that's always a SUCCESS.
    */
    command result_t StdControl.start() { return SUCCESS; }

    /**
     * Do nothing here - that's always a SUCCESS.
    */   
    command result_t StdControl.stop() { return SUCCESS; }

}
