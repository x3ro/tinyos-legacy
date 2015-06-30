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
 * Date last modified: 04/30/03
 */

module RadioCommandsM{
	provides{
		interface IntCommand as RadioCommand;
		interface IntCommand as RadioFreqCommand;
	}
	uses{
		interface Timer;
#if defined(PLATFORM_MICA2) || defined(PLATFORM_MICA2DOT)
		interface CC1000Control;
		interface StdControl as CC1KStdCtl;
#elif defined(PLATFORM_MICA)
		interface Pot;
#endif
	}
}

implementation{
	uint16_t param_;

	command void RadioCommand.execute(uint16_t param){
#if defined(PLATFORM_MICA2) || defined(PLATFORM_MICA2DOT)
		signal RadioCommand.ack(call CC1000Control.SetRFPower(param));
#elif defined(PLATFORM_MICA)
		signal RadioCommand.ack(call Pot.init(param));
#endif
	}

	command void RadioFreqCommand.execute(uint16_t param){
#if defined(PLATFORM_MICA2) || defined(PLATFORM_MICA2DOT)
		if (param<=CC1K_PARAMS_SIZE){
			param_ = param;
			call Timer.start2(TIMER_ONE_SHOT,32000u);
		}
#endif
		signal RadioFreqCommand.ack(SUCCESS);
	}

	event result_t Timer.fired(){
		call CC1KStdCtl.stop();
		call CC1000Control.Tune(param_);
		return call CC1KStdCtl.start();
	}

}
