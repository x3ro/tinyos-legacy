// $Id: AttrHamamatsuM.nc,v 1.1.1.1 2007/11/05 19:09:05 jpolastre Exp $

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
 * Date:     5/26/2003
 *
 */
// component to expose Hamamatsu sensor reading as an attribute


/**
 * @author Wei Hong
 * @author Intel Research Berkeley Lab
 */
module AttrHamamatsuM
{
	provides interface StdControl;
	uses 
	{
		interface AttrRegister as Channel1Attr;
		interface AttrRegister as Channel2Attr;
	#ifdef PLATFORM_MICA2DOT
		interface ADC as Channel1;
		interface ADC as Channel2;
		interface SplitControl as SensorControl;
	#endif
	}
}
implementation
{
	char *channel1;
	char *channel2;
	bool started;
	bool ch1Starting;
	bool ch2Starting;

	command result_t StdControl.init()
	{
	  started = FALSE;
	  ch1Starting = FALSE;
	  ch2Starting = FALSE;
	  if (call Channel1Attr.registerAttr("hamatop", UINT16, 2) != SUCCESS)
			return FAIL;
	  if (call Channel2Attr.registerAttr("hamabot", UINT16, 2) != SUCCESS)
			return FAIL;
#ifdef PLATFORM_MICA2DOT
	return call SensorControl.init();
#else
	return SUCCESS;
#endif

}

#ifdef PLATFORM_MICA2DOT
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
#ifdef PLATFORM_MICA2DOT
		return call SensorControl.stop();
#else
		return SUCCESS;
#endif
	}

#ifdef PLATFORM_MICA2DOT
	event result_t SensorControl.stopDone()
	{
		started = FALSE;
		return SUCCESS;
	}
#endif

	event result_t Channel1Attr.startAttr()
	{
		if (started)
			return call Channel1Attr.startAttrDone();
		ch1Starting = TRUE;
		if (ch2Starting)
			return SUCCESS;
#ifdef PLATFORM_MICA2DOT
		return call SensorControl.start();
#else
		return SUCCESS;
#endif
	}

#ifdef PLATFORM_MICA2DOT
	event result_t SensorControl.startDone()
	{
		started = TRUE;
		if (ch1Starting)
		{
			ch1Starting = FALSE;
			call Channel1Attr.startAttrDone();
		}
		if (ch2Starting)
		{
			ch2Starting = FALSE;
			call Channel2Attr.startAttrDone();
		}
		return SUCCESS;
	}
#endif

	event result_t Channel1Attr.getAttr(char *name, char *resultBuf, SchemaErrorNo *errorNo)
	{
		channel1 = resultBuf;
		*(uint16_t*)channel1 = 0xffff;
		*errorNo = SCHEMA_ERROR;
#ifdef PLATFORM_MICA2DOT
		if (call Channel1.getData() != SUCCESS)
			return FAIL;
#else
		return FAIL;
#endif

		*errorNo = SCHEMA_RESULT_PENDING;
		return SUCCESS;
	}

#ifdef PLATFORM_MICA2DOT
	async event result_t Channel1.dataReady(uint16_t data)
	{
		*(uint16_t*)channel1 = data;
		call Channel1Attr.getAttrDone("hamatop", channel1, SCHEMA_RESULT_READY);
		return SUCCESS;
	}
#endif

	event result_t Channel1Attr.setAttr(char *name, char *attrVal)
	{
		return FAIL;
	}

	event result_t Channel2Attr.startAttr()
	{
		if (started)
			return call Channel2Attr.startAttrDone();
		ch2Starting = TRUE;
		if (ch1Starting)
			return SUCCESS;
#ifdef PLATFORM_MICA2DOT
		return call SensorControl.start();
#else
		return SUCCESS;
#endif
	}

	event result_t Channel2Attr.getAttr(char *name, char *resultBuf, SchemaErrorNo *errorNo)
	{
		channel2 = resultBuf;
		*(uint16_t*)channel2 = 0xffff;
		*errorNo = SCHEMA_ERROR;
#ifdef PLATFORM_MICA2DOT
		if (call Channel2.getData() != SUCCESS)
			return FAIL;
#else
		return FAIL;
#endif
		*errorNo = SCHEMA_RESULT_PENDING;
		return SUCCESS;
	}

#ifdef PLATFORM_MICA2DOT
	async event result_t Channel2.dataReady(uint16_t data)
	{
		*(uint16_t*)channel2 = data;
		call Channel2Attr.getAttrDone("hamabot", channel2, SCHEMA_RESULT_READY);
		return SUCCESS;
	}
#endif

	event result_t Channel2Attr.setAttr(char *name, char *attrVal)
	{
		return FAIL;
	}
}
