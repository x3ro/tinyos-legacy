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
 * Author: Gabor Pap, Janos Sallai
 * Contact: Janos Sallai (sallai@isis.vanderbilt.edu)
 * Date last modified: 02/02/05
 */


/**
 * The VoltageCommands allows you to query the current voltage of the
 * motes. The voltage as returned by the ADC is reported back.
 *
 * @author Gabor Pap, Janos Sallai
 * @modified 02/02/05
 */ 

 
module VoltageCommandsM{
	provides{
		interface IntCommand;
	}
	uses{
		interface ADC;
	}
}

implementation{

    //***
    // Globals

	norace uint16_t voltage;

    //***
    // IntCommand interface

    /**
     * Sample battery voltage.
     */
	command void IntCommand.execute(uint16_t param){
		call ADC.getData();
	}
	
	
    /**
     * Implement synchronous sending of acknowledgement.
     */
	task void sendAck(){
		signal IntCommand.ack(voltage);
	}


    //***
    // ADC interface
    
    /**
     * Copy sample value to global variable and post a task so that
     * the acknowledgement is signaled from a synchronous context.
     */
	async event result_t ADC.dataReady(uint16_t data){
		voltage = data;
		post sendAck();
		return SUCCESS;
	}
}
