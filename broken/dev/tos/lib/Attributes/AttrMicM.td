/*									tab:4
 *  IMPORTANT: READ BEFORE DOWNLOADING, COPYING, INSTALLING OR USING.  By
 *  downloading, copying, installing or using the software you agree to
 *  this license.  If you do not agree to this license, do not download,
 *  install, copy or use the software.
 *
 *  Intel Open Source License 
 *
 *  Copyright (c) 2002 Intel Corporation 
 *  All rights reserved. 
 *  Redistribution and use in source and binary forms, with or without
 *  modification, are permitted provided that the following conditions are
 *  met:
 * 
 *	Redistributions of source code must retain the above copyright
 *  notice, this list of conditions and the following disclaimer.
 *	Redistributions in binary form must reproduce the above copyright
 *  notice, this list of conditions and the following disclaimer in the
 *  documentation and/or other materials provided with the distribution.
 *      Neither the name of the Intel Corporation nor the names of its
 *  contributors may be used to endorse or promote products derived from
 *  this software without specific prior written permission.
 *  
 *  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 *  ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 *  LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
 *  PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE INTEL OR ITS
 *  CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 *  EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 *  PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 *  PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 *  LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 *  NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 *  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * 
 */
/* 
 * Authors:  Wei Hong
 *           Intel Research Berkeley Lab
 * Date:     8/12/2002
 *
 */
// component to expose Mic readings as an attribute
module AttrMicM
{
	provides interface StdControl;
	uses 
	{
		interface ADC as MicADC;
		interface ADC as RawMicADC;
		interface StdControl as MicControl;
		interface Mic;
		interface AttrRegister as AttrNoise;
		interface AttrRegister as AttrRawMic;
		interface AttrRegister as AttrTones;
		interface AttrRegister as AttrRawTone;
		interface Timer as NoiseSampleTimer;
		interface Timer as ToneDetectTimer;
		interface Leds;
	}
}
implementation
{
	uint16_t tones;
	bool toneDetectRunning;
	bool noiseSampleRunning;
	uint16_t maxNoise;
	char *result;
	char *attrName;

	command result_t StdControl.init()
	{
		// noise max MIC ADC reading at 32 samples/second
		if (call AttrNoise.registerAttr("noise", UINT16, 2) != SUCCESS)
			return FAIL;
		// rawmic is just a single MIC ADC reading
		if (call AttrRawMic.registerAttr("rawmic", UINT16, 2) != SUCCESS)
			return FAIL;
		// tones is the number of tones detected at 32 samples/second
		if (call AttrTones.registerAttr("tones", UINT16, 2) != SUCCESS)
			return FAIL;
		// rawtone returns 1 if a tone is detected, -1 if not detected
		if (call AttrRawTone.registerAttr("rawtone", UINT16, 2) != SUCCESS)
			return FAIL;
		toneDetectRunning = FALSE;
		noiseSampleRunning = FALSE;
		return call MicControl.init();
	}

	command result_t StdControl.start()
	{
		call Mic.muxSel(1);
		call Mic.gainAdjust(64);
		return call MicControl.start();
	}

	command result_t StdControl.stop()
	{
		return call MicControl.stop();
	}

	void startNoiseSample()
	{
		noiseSampleRunning = TRUE;
		call NoiseSampleTimer.start(TIMER_REPEAT, 32);
	}

	void stopNoiseSample()
	{
		noiseSampleRunning = FALSE;
		call NoiseSampleTimer.stop();
	}

	event result_t AttrNoise.getAttr(char *name, char *resultBuf, SchemaErrorNo *errorNo)
	{
		if (!noiseSampleRunning)
			startNoiseSample();
		*(uint16_t*)resultBuf = maxNoise;
		*errorNo = SCHEMA_RESULT_READY;
		maxNoise = 0;
		return SUCCESS;
	}

	event result_t NoiseSampleTimer.fired()
	{
		if (call MicADC.getData() != SUCCESS)
			return FAIL;
		return SUCCESS;
	}

	event result_t AttrNoise.setAttr(char *name, char *attrVal)
	{
		return FAIL;
	}

	event result_t MicADC.dataReady(uint16_t data)
	{
		if (maxNoise < data)
			maxNoise = data;
		return SUCCESS;
	}

	void toneDetectStart()
	{
		tones = 0;
		toneDetectRunning = TRUE;
		call ToneDetectTimer.start(TIMER_REPEAT, 32);
	}

	void toneDetectStop()
	{
		toneDetectRunning = FALSE;
		call ToneDetectTimer.stop();
	}

	event result_t AttrTones.getAttr(char *name, char *resultBuf, SchemaErrorNo *errorNo)
	{
		if (!toneDetectRunning)
			toneDetectStart();
		*resultBuf = tones;
		*errorNo = SCHEMA_RESULT_READY;
		tones = 0;
		return SUCCESS;
	}

	event result_t ToneDetectTimer.fired()
	{
		uint8_t in;
		in = call Mic.readToneDetector();
		if (in == 0)
		{
			if (tones < 32)
				tones++;
		}
		else
		{
			if (tones > 0)
				tones--;
		}
		return SUCCESS;
	}

	event result_t AttrTones.setAttr(char *name, char *attrVal)
	{
		return FAIL;
	}

	event result_t AttrRawMic.getAttr(char *name, char *resultBuf, SchemaErrorNo *errorNo)
	{
		if (call RawMicADC.getData() != SUCCESS)
			return FAIL;
		result = resultBuf;
		attrName = name;
		*errorNo = SCHEMA_RESULT_PENDING;
		return SUCCESS;
	}

	event result_t RawMicADC.dataReady(uint16_t data)
	{
		*(uint16_t*)result = data;
		return call AttrRawMic.getAttrDone(attrName, result, SCHEMA_RESULT_READY);
	}

	event result_t AttrRawMic.setAttr(char *name, char *attrVal)
	{
		return FAIL;
	}

	event result_t AttrRawTone.getAttr(char *name, char *resultBuf, SchemaErrorNo *errorNo)
	{
		uint8_t in;
		in = call Mic.readToneDetector();
		if (in == 0)
			*(uint16_t*)resultBuf = 1;
		else
			*(uint16_t*)resultBuf = 0;
		*errorNo = SCHEMA_RESULT_READY;
		return SUCCESS;
	}

	event result_t AttrRawTone.setAttr(char *name, char *attrVal)
	{
		return FAIL;
	}
}
