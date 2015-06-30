// $Id: AttrMicM.nc,v 1.1.1.1 2007/11/05 19:09:05 jpolastre Exp $
/*									tab:4
 * "Copyright (c) 2000-2003 The Regents of the University  of California.  
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY OF
 * CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 *
 * Copyright (c) 2002-2003 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */

/* 
 * Authors:  Wei Hong
 *           Intel Research Berkeley Lab
 * Date:     8/12/2002
 *
 */
// component to expose Mic readings as an attribute


/**
 * @author Wei Hong
 * @author Intel Research Berkeley Lab
 */
module AttrMicM
{
	provides interface StdControl;
	uses 
	{
		interface ADC as MicADC;
		interface StdControl as MicControl;
		interface Mic;
		interface AttrRegister as AttrNoise;
		interface AttrRegister as AttrTones;
#ifdef kRAW_MIC_ATTRS
		interface AttrRegister as AttrRawMic;
		interface AttrRegister as AttrRawTone;
		interface ADC as RawMicADC;
#endif
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

	void startNoiseSample();
	void stopNoiseSample();
	void toneDetectStart();
	void toneDetectStop();


	command result_t StdControl.init()
	{
		// noise max MIC ADC reading at 32 samples/second
		if (call AttrNoise.registerAttr("noise", UINT16, 2) != SUCCESS)
			return FAIL;
		// tones is the number of tones detected at 32 samples/second
		if (call AttrTones.registerAttr("tones", UINT16, 2) != SUCCESS)
			return FAIL;
#ifdef kRAW_MIC_ATTRS
		// rawmic is just a single MIC ADC reading
		if (call AttrRawMic.registerAttr("rawmic", UINT16, 2) != SUCCESS)
			return FAIL;
		// rawtone returns 1 if a tone is detected, -1 if not detected
		if (call AttrRawTone.registerAttr("rawtone", UINT16, 2) != SUCCESS)
			return FAIL;
#endif
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
		stopNoiseSample();
		toneDetectStop();
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


	event result_t AttrNoise.startAttr()
	{
		if (!noiseSampleRunning)
			startNoiseSample();
		return call AttrNoise.startAttrDone();
	}

	event result_t AttrNoise.getAttr(char *name, char *resultBuf, SchemaErrorNo *errorNo)
	{
	  atomic {
		*(uint16_t*)resultBuf = maxNoise;
	  }
		*errorNo = SCHEMA_RESULT_READY;
		atomic {
		  maxNoise = 0;
		}
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

	async event result_t MicADC.dataReady(uint16_t data)
	{
	  atomic {
		if (maxNoise < data)
			maxNoise = data;
	  }
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

	event result_t AttrTones.startAttr()
	{
		if (!toneDetectRunning)
			toneDetectStart();
		return call AttrTones.startAttrDone();
	}

	event result_t AttrTones.getAttr(char *name, char *resultBuf, SchemaErrorNo *errorNo)
	{
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

#ifdef kRAW_MIC_ATTRS
	event result_t AttrRawMic.startAttr()
	{
		return call AttrRawMic.startAttrDone();
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

	event result_t AttrRawTone.startAttr()
	{
		return call AttrRawTone.startAttrDone();
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
#endif /* kRAW_MIC_ATTRS */
}
