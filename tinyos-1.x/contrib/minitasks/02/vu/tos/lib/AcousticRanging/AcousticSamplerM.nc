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
 *
 * Author: Miklos Maroti, Branislav Kusy
 * Date last modified: 03/21/03
 */

includes AcousticBeaconMsg;

module AcousticSamplerM
{
	provides 
	{
		interface AcousticSampler;
		interface StdControl;
	}
	uses
	{
		interface RadioSuspend;
		interface ADC as MicADC;
		interface Mic;
		interface StdControl as MicControl;
		interface ReceiveMsg;
	}
}

implementation
{
	command result_t StdControl.init()
	{
		call RadioSuspend.init();
		call MicControl.init();
		return SUCCESS;
	}

	command result_t StdControl.start() 
	{
		return SUCCESS;
	}
	
	command result_t StdControl.stop()
	{
		call MicControl.stop();
		return SUCCESS;
	}

	command void AcousticSampler.setGain(uint8_t gain)
	{
		if( gain != 0 )
		{
			call MicControl.start();
			call Mic.muxSel(1);		// get mic before the bandpass filter
			call Mic.gainAdjust(gain);
		}
		else
			call MicControl.stop();
	}

	task void suspendRadio();

	event TOS_MsgPtr ReceiveMsg.receive(TOS_MsgPtr p)
	{
		AcousticBeaconMsg *msg = (AcousticBeaconMsg*)&p->data;
		if( signal AcousticSampler.receive(msg->nodeId) == SUCCESS )
			post suspendRadio();

		return p;
	}

	// must suspend the radio from a task
	task void suspendRadio()
	{
		if( call RadioSuspend.suspend() == SUCCESS )
		{
			// start sampling
			call MicADC.getContinuousData();
		}
		else
		{
			// bail out
			signal AcousticSampler.receiveDone();
		}
	}

	task void resumeRadio();

	event result_t MicADC.dataReady(uint16_t mic)
	{
		if( signal AcousticSampler.dataReady(mic) == SUCCESS )
			return SUCCESS;

		post resumeRadio();
		return FAIL;
	}

	task void resumeRadio()
	{
		call RadioSuspend.resume();
		signal AcousticSampler.receiveDone();
	}
}
