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
 * Author: Miklos Maroti
 * Date last modified: 04/11/03
 */

includes Timer;

module TimedSoundRecorderM
{
	provides 
	{
		interface StdControl;
	}
	uses
	{
		interface CC1000Control;
		interface ADC as MicADC;
		interface Mic;
		interface StdControl as MicControl;
		interface Leds;
		interface RadioSuspend;
		interface SendBigMsg;
		interface Timer as TimeoutTimer;
		interface GlobalTime;
		interface LocalTime;
		interface DiagMsg;
		interface RemoteControl;
		interface StdControl as TimeSyncControl;
	}
}

implementation
{
	enum
	{
		BUFFER_LENGTH = 2200,
		SILENCE_LENGTH = 1000,
		ENERGY_THRESHOLD = 40,
		MIC_GAIN = 15,
		BASE_STATION = 0,

		TIMER_TIMEOUT = 32000u,	// in jiffies	(1 sec)
		TIMEOUT_LISTEN = 60,	// in seconds
		GLOBAL_PERIOD = 90,	// in seconds
	};

	uint8_t buffer[BUFFER_LENGTH];
	uint16_t bufferIndex;		// the position of the next sample
	uint16_t recordCounter;		// the number of samples remaining

	uint16_t decayingAverage;	// the higher byte contains the average
	uint16_t decayingEnergy;	// the same decay, 255/256

	enum
	{
		STATE_LISTEN,
		STATE_RECORD,
		STATE_SEND,
		STATE_SYNC,
	};

	uint8_t state;			// the current state
	int16_t timeout;		// remaining time in this state

	struct
	{
		uint16_t nodeID;
		uint32_t globalTime;	// time of big noise
		uint32_t localTime;
	} header;

	bool report;			// report the header in a diag msg

	void clearBuffer()
	{
		// clear the buffer
		uint16_t i = BUFFER_LENGTH;
		do { buffer[--i] = 128; } 
		while( i != 0 );

		// initialize
		decayingAverage = 128 << 8;
		decayingEnergy = 0;
	}

	command result_t StdControl.init()
	{
		call Leds.init();
		call CC1000Control.SetRFPower(0xFF);
		call MicControl.init();

		return SUCCESS;
	}

	task void startSampling();

	command result_t StdControl.start() 
	{
		call MicControl.start();
		call Mic.muxSel(1);		// get mic before the bandpass filter
		call Mic.gainAdjust(MIC_GAIN);

		state = STATE_SYNC;
		report = FALSE;

		call TimeoutTimer.start2(TIMER_REPEAT, TIMER_TIMEOUT);

		return SUCCESS;
	}
	
	command result_t StdControl.stop()
	{
		state = STATE_SYNC;
		report = FALSE;

		call TimeoutTimer.stop();
		call MicControl.stop();

		return SUCCESS;
	}

	task void startSampling();
	task void stopSampling();
	task void abortSampling();

	event result_t TimeoutTimer.fired()
	{
		uint32_t globalTime;

		if( state == STATE_SYNC )
		{
			call Leds.yellowToggle();

			if( report && call DiagMsg.record() )
			{
				call DiagMsg.str("snd");
				call DiagMsg.uint16(TOS_LOCAL_ADDRESS);
				call DiagMsg.uint32(header.globalTime);
				call DiagMsg.uint32(header.localTime);
				call DiagMsg.send();

				report = FALSE;
			}
		}

		switch( state )
		{
		case STATE_LISTEN:
			atomic
			{
				if( --timeout <= 0 )
					state = STATE_SYNC;
			}

			break;

		case STATE_SYNC:

			call GlobalTime.getGlobalTime(&globalTime);
			globalTime /= 32768u;		// change to seconds

			if( (globalTime % GLOBAL_PERIOD) >= GLOBAL_PERIOD - 2 )
			{
				atomic
				{
					timeout = TIMEOUT_LISTEN;
					state = STATE_LISTEN;
				}
				post startSampling();
			}
			break;
		}

		return SUCCESS;
	}

	task void startSampling()
	{
		if( state == STATE_LISTEN 
			&& call RadioSuspend.suspend() == SUCCESS )
		{
			clearBuffer();
			atomic bufferIndex = 0;

			call Leds.yellowOn();

			// start sampling
			call MicADC.getContinuousData();
		}
		else
		{
			atomic
			{
				timeout = TIMEOUT_LISTEN;
				state = STATE_SYNC;
			}
		}
	}

	event result_t MicADC.dataReady(uint16_t mic)
	{
		uint8_t sample, average, energy;

		// drop the lower two bits
		sample = mic >> 2;

		if( bufferIndex == 0 )
			call Leds.yellowToggle();

		// record the sample
		atomic
		{
			if( bufferIndex >= BUFFER_LENGTH )	// THIS SHOULD BE UNNECESSARY
				bufferIndex = 0;

			buffer[bufferIndex] = sample;

			if( ++bufferIndex >= BUFFER_LENGTH )
				bufferIndex = 0;
		}

		switch( state )
		{
		case STATE_LISTEN:

			// calculate the decayed average
			average = decayingAverage >> 8;	// very fast: 0 or 1 CPU cycle
			decayingAverage -= average;
			decayingAverage += sample;

			// compute the amplitude
			if( sample >= average )
				sample -= average;
			else
				sample = average - sample;

			// calculate the decayed energy
			energy = decayingEnergy >> 8;	// very fast: 0 or 1 CPU cycle
			decayingEnergy -= energy;
			decayingEnergy += sample;

			if( energy > ENERGY_THRESHOLD )
			{
				state = STATE_RECORD;

				report = FALSE;
				header.localTime = call LocalTime.read();

				recordCounter = BUFFER_LENGTH - SILENCE_LENGTH;
			}
			break;

		case STATE_RECORD:
			if( --recordCounter == 0 )
			{
				state = STATE_SEND;
				post stopSampling();

				return FAIL;
			}
			break;
		
		default:
			post abortSampling();
			return FAIL;
		}

		return SUCCESS;
	}

	task void abortSampling()
	{
		call Leds.yellowOff();
		call RadioSuspend.resume();
	}

	task void stopSampling()
	{
		call Leds.yellowOn();
		call RadioSuspend.resume();

		header.globalTime = header.localTime;
		call GlobalTime.local2Global(&header.globalTime);
		header.nodeID = TOS_LOCAL_ADDRESS;

		if( call SendBigMsg.send3(BASE_STATION,
			&header, &header + 1,
			buffer + bufferIndex, buffer + BUFFER_LENGTH,
			buffer, buffer + bufferIndex) != SUCCESS )
		{
			signal SendBigMsg.sendDone(FAIL);
		}
	}

	void event SendBigMsg.sendDone(result_t success)
	{
		call Leds.yellowOff();

		atomic
		{
			state = STATE_SYNC;
			report = TRUE;
		}
	}

	event void RemoteControl.start(){
		call MicControl.start();
		call Mic.muxSel(1);		// get mic before the bandpass filter
		call Mic.gainAdjust(MIC_GAIN);

		state = STATE_SYNC;
		report = FALSE;

		call TimeoutTimer.start2(TIMER_TIMEOUT);
		call TimeSyncControl.start();
	}
	
	event void RemoteControl.stop(){
		state = STATE_SYNC;
		report = FALSE;

		call TimeoutTimer.stop();
		call MicControl.stop();
		call TimeSyncControl.stop();
	}

	event void RemoteControl.reconfig(uint8_t* newConfig){}


}
