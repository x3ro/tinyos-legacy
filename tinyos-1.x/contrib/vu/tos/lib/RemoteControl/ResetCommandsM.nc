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
 * Author: Brano Kusy
 * Contact: Janos Sallai (sallai@isis.vanderbilt.edu)
 * Date last modified: 02/02/05
 */

/**
 * ResetCommands allow for remotely reset the mote.
 *
 * @author Brano Kusy
 * @modified 02/02/05
 */ 


includes Reset;
 
module ResetCommandsM{
	provides{
		interface IntCommand;
		interface StdControl;
	}
	uses{
		interface Timer;
		interface Random;
	}
}

implementation{

    //***
    // StdControl interface

    /**
     * Initialize random number generator.
     */
	command result_t StdControl.init(){ 
		call Random.init(); 
		return SUCCESS;
	}
	command result_t StdControl.start(){ return SUCCESS; }
	command result_t StdControl.stop(){ return SUCCESS; }


    //***
    // IntCommand interface

    /**
     * Defer reset with a random time interval, which makes sure
     * that the reset nodes will have different clock values.
     */
	command void IntCommand.execute(uint16_t param){
		uint16_t delay = (call Random.rand() & 2047) | 1024;
		call Timer.start(TIMER_ONE_SHOT,((uint32_t)delay) * param);
		signal IntCommand.ack(SUCCESS);
	}


    //***
    // Timer interface
	
	/**
	 * Execute deferred reset.
	 */
	event result_t Timer.fired(){
		resetMote();

		return SUCCESS;
	}
}


