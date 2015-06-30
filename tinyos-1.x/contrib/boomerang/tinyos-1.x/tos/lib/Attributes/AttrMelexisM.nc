// $Id: AttrMelexisM.nc,v 1.1.1.1 2007/11/05 19:09:05 jpolastre Exp $

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
 * Date:     3/25/2003
 *
 */
// component to expose Melexis sensor readings as attributes


/**
 * @author Wei Hong
 * @author Intel Research Berkeley Lab
 */
module AttrMelexisM
{
	provides interface StdControl;
	uses 
	{
		interface AttrRegister as ThermoAttr;
		interface AttrRegister as TempAttr;
		interface ADC as Thermopile;
		interface ADC as Temperature;
		// interface Calibration;
		interface SplitControl as SensorControl;
	}
}
implementation
{
	char *thermopile;
	char *temp;
	bool started;
	bool thermoStarting;
	bool tempStarting;

	command result_t StdControl.init()
	{
	  started = FALSE;
	  thermoStarting = FALSE;
	  tempStarting = FALSE;
	  if (call ThermoAttr.registerAttr("thermo", UINT16, 2) != SUCCESS)
			return FAIL;
	  if (call TempAttr.registerAttr("thmtemp", UINT16, 2) != SUCCESS)
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

	event result_t ThermoAttr.startAttr()
	{
		if (started)
			return call ThermoAttr.startAttrDone();
		thermoStarting = TRUE;
		if (tempStarting)
			return SUCCESS;
		return call SensorControl.start();
	}

	event result_t SensorControl.startDone()
	{
		started = TRUE;
		if (thermoStarting)
		{
			thermoStarting = TRUE;
			call ThermoAttr.startAttrDone();
		}
		if (tempStarting)
		{
			tempStarting = TRUE;
			call TempAttr.startAttrDone();
		}
		return SUCCESS;
	}

	event result_t ThermoAttr.getAttr(char *name, char *resultBuf, SchemaErrorNo *errorNo)
	{
		thermopile = resultBuf;
		*(uint16_t*)thermopile = 0xffff;
		*errorNo = SCHEMA_ERROR;
		if (call Thermopile.getData() != SUCCESS)
			return FAIL;
		*errorNo = SCHEMA_RESULT_PENDING;
		return SUCCESS;
	}

	event result_t Thermopile.dataReady(uint16_t data)
	{
		*(uint16_t*)thermopile = data;
		call ThermoAttr.getAttrDone("thermo", thermopile, SCHEMA_RESULT_READY);
		return SUCCESS;
	}

	event result_t ThermoAttr.setAttr(char *name, char *attrVal)
	{
		return FAIL;
	}

	event result_t TempAttr.startAttr()
	{
		if (started)
			return call TempAttr.startAttrDone();
		tempStarting = TRUE;
		if (thermoStarting)
			return SUCCESS;
		return call SensorControl.start();
	}

	event result_t TempAttr.getAttr(char *name, char *resultBuf, SchemaErrorNo *errorNo)
	{
		temp = resultBuf;
		*(uint16_t*)temp = 0xffff;
		*errorNo = SCHEMA_ERROR;
		if (call Temperature.getData() != SUCCESS)
			return FAIL;
		*errorNo = SCHEMA_RESULT_PENDING;
		return SUCCESS;
	}

	event result_t Temperature.dataReady(uint16_t data)
	{
		*(uint16_t*)temp = data;
		call TempAttr.getAttrDone("thmtemp", temp, SCHEMA_RESULT_READY);
		return SUCCESS;
	}

	event result_t TempAttr.setAttr(char *name, char *attrVal)
	{
		return FAIL;
	}
}
