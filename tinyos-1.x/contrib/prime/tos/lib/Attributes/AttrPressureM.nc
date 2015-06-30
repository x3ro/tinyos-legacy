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
 * Date:     3/25/2003
 *
 */
// component to expose Intersema Pressure sensor reading as an attribute
module AttrPressureM
{
	provides interface StdControl;
	uses 
	{
		interface AttrRegister as PressureAttr;
		interface AttrRegister as TempAttr;
		interface ADC as Pressure;
		interface ADC as Temp;
		// interface Calibration;
		interface SplitControl as SensorControl;
	}
}
implementation
{
	char *pressure;
	char *temp;
	bool started;
	bool tempStarting;
	bool pressureStarting;

	command result_t StdControl.init()
	{
	  started = FALSE;
	  tempStarting = FALSE;
	  pressureStarting = FALSE;
	  if (call PressureAttr.registerAttr("press", UINT16, 2) != SUCCESS)
			return FAIL;
	  if (call TempAttr.registerAttr("prtemp", UINT16, 2) != SUCCESS)
			return FAIL;
	  return call SensorControl.init();
	}

	event result_t SensorControl.initDone()
	{
		return SUCCESS;
	}

	command result_t StdControl.start()
	{
	  return SUCCESS;
	}


	command result_t StdControl.stop()
	{
	  call SensorControl.stop();
	  return SUCCESS;
	}

	event result_t SensorControl.stopDone()
	{
	  started = FALSE;
	  return SUCCESS;
	}

	event result_t PressureAttr.startAttr()
	{
		if (started)
			return call PressureAttr.startAttrDone();
		pressureStarting = TRUE;
		if (tempStarting)
			return SUCCESS;
		return call SensorControl.start();
	}

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
		return SUCCESS;
	}

	event result_t PressureAttr.getAttr(char *name, char *resultBuf, SchemaErrorNo *errorNo)
	{
		pressure = resultBuf;
		*(uint16_t*)pressure = 0xffff;
		*errorNo = SCHEMA_ERROR;
		if (call Pressure.getData() != SUCCESS)
			return FAIL;
		*errorNo = SCHEMA_RESULT_PENDING;
		return SUCCESS;
	}

	event result_t Pressure.dataReady(uint16_t data)
	{
		*(uint16_t*)pressure = data;
		call PressureAttr.getAttrDone("press", pressure, SCHEMA_RESULT_READY);
		return SUCCESS;
	}

	event result_t PressureAttr.setAttr(char *name, char *attrVal)
	{
		return FAIL;
	}

	event result_t TempAttr.startAttr()
	{
		if (started)
			return call TempAttr.startAttrDone();
		tempStarting = TRUE;
		if (pressureStarting)
			return SUCCESS;
		return call SensorControl.start();
	}

	event result_t TempAttr.getAttr(char *name, char *resultBuf, SchemaErrorNo *errorNo)
	{
		temp = resultBuf;
		*(uint16_t*)temp = 0xffff;
		*errorNo = SCHEMA_ERROR;
		if (call Temp.getData() != SUCCESS)
			return FAIL;
		*errorNo = SCHEMA_RESULT_PENDING;
		return SUCCESS;
	}

	event result_t Temp.dataReady(uint16_t data)
	{
		*(uint16_t*)temp = data;
		call TempAttr.getAttrDone("prtemp", temp, SCHEMA_RESULT_READY);
		return SUCCESS;
	}

	event result_t TempAttr.setAttr(char *name, char *attrVal)
	{
		return FAIL;
	}
}
