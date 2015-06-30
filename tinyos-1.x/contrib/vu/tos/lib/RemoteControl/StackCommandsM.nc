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
 * Author: Gabor Pap
 * Contact: Janos Sallai (sallai@isis.vanderbilt.edu)
 * Date last modified: 02/02/05
 */

/**
 * StackCommandsM reports the maximum used and minimum avaiable stack space
 * on the motes.
 *
 * @author Gabor Pap
 * @modified 02/02/05
 */ 
 

module StackCommandsM{
	provides{
		interface IntCommand;
	}
	uses{
		interface PeaceKeeper;
	}
}

implementation{

    //***
    // IntCommand interface

    /**
     * Query PeaceKeeper for stack information and return it.
     */
	command void IntCommand.execute(uint16_t param){
		uint16_t returnValue = 0;
		if ( param == 0 ){
			returnValue = call PeaceKeeper.getMaxStack();
		}
			
		if ( param == 1){
			returnValue = call PeaceKeeper.getUnusedStack();
		}

		signal IntCommand.ack(returnValue);
	}
}
