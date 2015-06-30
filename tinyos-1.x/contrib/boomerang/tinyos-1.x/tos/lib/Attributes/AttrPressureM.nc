// $Id: AttrPressureM.nc,v 1.1.1.1 2007/11/05 19:09:06 jpolastre Exp $

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
// component to expose Intersema Pressure sensor reading as an attribute

/* 
 * Authors:  Wei Hong
 *           Intel Research Berkeley Lab
 * Date:     3/25/2003
 *
 */

#if defined(BOARD_MEP401)
#define PRESENT
#endif

/**
 * @author Wei Hong
 * @author Intel Research Berkeley Lab
 */
module AttrPressureM
{
	provides interface StdControl;
	uses 
	{
		interface AttrRegister as PressureAttr;
		interface AttrRegister as TempAttr;
		interface AttrRegister as CalibAttr;
#ifdef PRESENT
		interface ADC as Pressure;
		interface ADC as Temp;
		interface Calibration;
		interface SplitControl as SensorControl;
#endif
	}
}

implementation
{
	char *pressure;
	char *temp;
	char *calib;
	bool started;
	bool tempStarting;
	bool pressureStarting;
	bool calibStarting;
	short calibCount;

	command result_t StdControl.init()
	{
	  started = FALSE;
	  tempStarting = FALSE;
	  pressureStarting = FALSE;
	  calibStarting = FALSE;
	  if (call PressureAttr.registerAttr("press", UINT16, 2) != SUCCESS)
	      return FAIL;
	  if (call TempAttr.registerAttr("prtemp", UINT16, 2) != SUCCESS)
	      return FAIL;
	  if (call CalibAttr.registerAttr("prcalib", BYTES, 8) != SUCCESS)
	      return FAIL;

#ifdef PRESENT
	  return call SensorControl.init();
#else
	  return SUCCESS;
#endif
	}

#ifdef PRESENT
	event result_t SensorControl.initDone()
	{
	  return SUCCESS;
	}
#endif

	command result_t StdControl.start()
	{
	  return SUCCESS;
	}

	command result_t StdControl.stop()
	{
#ifdef PRESENT
	  call SensorControl.stop();
#endif
	  return SUCCESS;
	}

#ifdef PRESENT
	event result_t SensorControl.stopDone()
	{
	  started = FALSE;
	  return SUCCESS;
	}
#endif

	event result_t PressureAttr.startAttr()
	{
		if (started)
			return call PressureAttr.startAttrDone();
		pressureStarting = TRUE;
		if (tempStarting || calibStarting)
			return SUCCESS;
#ifdef PRESENT
		return call SensorControl.start();
#else
		return SUCCESS;
#endif
	}

#ifdef PRESENT
	event result_t SensorControl.startDone()
	{
		started = TRUE;
		if (pressureStarting)
		{
			pressureStarting = FALSE;
			call PressureAttr.startAttrDone();
		}
		if (tempStarting)
		{
			tempStarting = FALSE;
			call TempAttr.startAttrDone();
		}
		if (calibStarting)
		{
			calibStarting = FALSE;
			call CalibAttr.startAttrDone();
		}
		return SUCCESS;
	}
#endif

	event result_t PressureAttr.getAttr(char *name, char *resultBuf, SchemaErrorNo *errorNo)
	{
		pressure = resultBuf;
		*(uint16_t*)pressure = 0xffff;
		*errorNo = SCHEMA_ERROR;
#ifdef PRESENT
		if (call Pressure.getData() != SUCCESS)
			return FAIL;
#else
		return FAIL;
#endif

		*errorNo = SCHEMA_RESULT_PENDING;
		return SUCCESS;
	}

#ifdef PRESENT
	async event result_t Pressure.dataReady(uint16_t data)
	{
		*(uint16_t*)pressure = data;
		call PressureAttr.getAttrDone("press", pressure, SCHEMA_RESULT_READY);
		return SUCCESS;
	}
#endif

	event result_t PressureAttr.setAttr(char *name, char *attrVal)
	{
		return FAIL;
	}

	event result_t TempAttr.startAttr()
	{
		if (started)
			return call TempAttr.startAttrDone();
		tempStarting = TRUE;
		if (pressureStarting || calibStarting)
			return SUCCESS;
#ifdef PRESENT
		return call SensorControl.start();
#else
		return SUCCESS;
#endif
	}


	event result_t TempAttr.getAttr(char *name, char *resultBuf, SchemaErrorNo *errorNo)
	{
		temp = resultBuf;
		*(uint16_t*)temp = 0xffff;
		*errorNo = SCHEMA_ERROR;
#ifdef PRESENT
		if (call Temp.getData() != SUCCESS)
			return FAIL;
#else
		return FAIL;
#endif
		*errorNo = SCHEMA_RESULT_PENDING;
		return SUCCESS;
	}



#ifdef PRESENT
	async event result_t Temp.dataReady(uint16_t data)
	{
		*(uint16_t*)temp = data;
		call TempAttr.getAttrDone("prtemp", temp, SCHEMA_RESULT_READY);
		return SUCCESS;
	}
#endif

	event result_t TempAttr.setAttr(char *name, char *attrVal)
	{
		return FAIL;
	}

	event result_t CalibAttr.startAttr()
	{
		if (started)
			return call CalibAttr.startAttrDone();
		calibStarting = TRUE;
		if (tempStarting || pressureStarting)
			return SUCCESS;
#ifdef PRESENT
		return call SensorControl.start();
#else
		return SUCCESS;
#endif
	}

	event result_t CalibAttr.getAttr(char *name, char *resultBuf, SchemaErrorNo *errorNo)
	{
		calib = resultBuf;
		calibCount = 0;
		*errorNo = SCHEMA_ERROR;
#ifdef PRESENT
		if (call Calibration.getData() != SUCCESS)
			return FAIL;
#else
		return FAIL;
#endif

		*errorNo = SCHEMA_RESULT_PENDING;
		return SUCCESS;
	}

#ifdef PRESENT
	event result_t Calibration.dataReady(char word, uint16_t data)
	{
		calibCount++;
		*(uint16_t*)(calib + (word - 1) * 2) = data;
		if (calibCount == 4)
			call CalibAttr.getAttrDone("prcalib", calib, SCHEMA_RESULT_READY);
		return SUCCESS;
	}
#endif

	event result_t CalibAttr.setAttr(char *name, char *attrVal)
	{
		return FAIL;
	}
}
