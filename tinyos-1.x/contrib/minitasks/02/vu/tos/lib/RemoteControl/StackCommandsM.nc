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
 * Date last modified: 04/30/03
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
	command void IntCommand.execute(uint16_t param){
		uint8_t returnValue = 0;
		if ( param == 0 ){
			uint16_t maxStack = call PeaceKeeper.getMaxStack();
			maxStack = maxStack >> 2;
			if (maxStack > 255){
			    returnValue = 255;
			} else{
			    returnValue = (uint8_t) maxStack;
			}
		}
			
		if ( param == 1){
			uint16_t freeStack = call PeaceKeeper.getUnusedStack();
			freeStack = freeStack >> 2;
			if (freeStack > 255){
			    returnValue = 255;
			} else{
			    returnValue = (uint8_t) freeStack;
			}
		}

		signal IntCommand.ack(returnValue);
	}
}
