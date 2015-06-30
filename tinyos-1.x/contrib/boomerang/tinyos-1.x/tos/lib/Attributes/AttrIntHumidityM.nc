// $Id: AttrIntHumidityM.nc,v 1.1.1.1 2007/11/05 19:09:05 jpolastre Exp $

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
// component to expose Sensirion humidity sensor reading as an attribute

/**
 * @author Wei Hong, Alan Mainwaring
 * @author Intel Research Berkeley Lab
 */

#if defined(BOARD_MEP401)
#define PRESENT
#endif

module AttrIntHumidityM
{
	provides interface StdControl;
	uses 
	{
		interface AttrRegister as HumidityAttr;
		interface AttrRegister as TempAttr;
#ifdef PRESENT
		interface ADC as Humidity;
		interface ADC as Temperature;
		interface SplitControl as SensorControl;
#endif
	}
}

implementation
{
	char *humidity;
	char *temp;
	bool started;
	bool humidityStarting;
	bool tempStarting;

	command result_t StdControl.init()
	{
	  started = FALSE;
	  humidityStarting = FALSE;
	  tempStarting = FALSE;
	  if (call HumidityAttr.registerAttr("inthum", UINT16, 2) != SUCCESS)
			return FAIL;
	  if (call TempAttr.registerAttr("inthumt", UINT16, 2) != SUCCESS)
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


	command result_t StdControl.stop() {
#ifdef PRESENT
		return call SensorControl.stop();
#else
		return SUCCESS;
#endif
	}

#ifdef PRESENT
	event result_t SensorControl.stopDone()
	{
	    started = FALSE;
		return SUCCESS;
	}
#endif

	event result_t HumidityAttr.startAttr()
	{
		if (started)
			return call HumidityAttr.startAttrDone();
		humidityStarting = TRUE;
		if (tempStarting)
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
		if (humidityStarting)
		{
			humidityStarting = FALSE;
			call HumidityAttr.startAttrDone();
		}
		if (tempStarting)
		{
			tempStarting = FALSE;
			call TempAttr.startAttrDone();
		}
		return SUCCESS;
	}
#endif
	event result_t HumidityAttr.getAttr(char *name, char *resultBuf, SchemaErrorNo *errorNo)
	{
		humidity = resultBuf;
		*(uint16_t*)humidity = 0xffff;
		*errorNo = SCHEMA_ERROR;
#ifndef PRESENT
		return FAIL;
#else
		if (call Humidity.getData() != SUCCESS)
			return FAIL;
#endif
		*errorNo = SCHEMA_RESULT_PENDING;
		return SUCCESS;
	}

#ifdef PRESENT
	async event result_t Humidity.dataReady(uint16_t data)
	{
		*(uint16_t*)humidity = data;
		call HumidityAttr.getAttrDone("inthum", humidity, SCHEMA_RESULT_READY);
		return SUCCESS;
	}
#endif

	event result_t HumidityAttr.setAttr(char *name, char *attrVal)
	{
		return FAIL;
	}

	event result_t TempAttr.startAttr()
	{
		if (started)
			return call TempAttr.startAttrDone();
		tempStarting = TRUE;
		if (humidityStarting)
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
#ifndef PRESENT
		return FAIL;
#else
		if (call Temperature.getData() != SUCCESS)
			return FAIL;
#endif
		*errorNo = SCHEMA_RESULT_PENDING;
		return SUCCESS;
	}
#ifdef PRESENT
	async event result_t Temperature.dataReady(uint16_t data)
	{
		*(uint16_t*)temp = data;
		call TempAttr.getAttrDone("inthumt", temp, SCHEMA_RESULT_READY);
		return SUCCESS;
	}
#endif

	event result_t TempAttr.setAttr(char *name, char *attrVal)
	{
		return FAIL;
	}
}
