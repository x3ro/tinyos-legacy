// $Id: AttrTaosPhotoM.nc,v 1.1.1.1 2007/11/05 19:09:06 jpolastre Exp $

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
// component to expose Photo sensor reading as an attribute


/**
 * @author Wei Hong
 * @author Intel Research Berkeley Lab
 */
module AttrTaosPhotoM
{
	provides interface StdControl;
	uses 
	{
		interface AttrRegister as TaosBotAttr;
		interface AttrRegister as TaosTopAttr;
#ifdef PLATFORM_MICA2DOT
		interface ADC as TaosCh0;
		interface ADC as TaosCh1;
		interface SplitControl as SensorControl;
#endif
	}
}
implementation
{
        char *photoBot;
	char *photoTop;
	bool started;
	bool photoBotStarting;
	bool photoTopStarting;
	uint16_t topData;
	uint16_t botData;
	
	enum {DATA_NULL = 0xFFFF};
	
	command result_t StdControl.init()
	{
	  started = FALSE;
	  photoBotStarting = FALSE;
	  photoTopStarting = FALSE;
	  photoBot = NULL;
	  photoTop = NULL;
	  if (call TaosBotAttr.registerAttr("taosbot", UINT16, 2) != SUCCESS)
	    return FAIL;
	  if (call TaosTopAttr.registerAttr("taostop", UINT16, 2) != SUCCESS)
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

	event result_t TaosBotAttr.startAttr()
	{
		if (started)
			return call TaosBotAttr.startAttrDone();
		photoBotStarting = TRUE;
		botData = DATA_NULL;
		topData = DATA_NULL;
		if (photoTopStarting)
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
		if (photoBotStarting)
		{
			photoBotStarting = FALSE;
			call TaosBotAttr.startAttrDone();
		}
		if (photoTopStarting)
		{
			photoTopStarting = FALSE;
			call TaosTopAttr.startAttrDone();
		}
		return SUCCESS;
	}
#endif

	event result_t TaosBotAttr.getAttr(char *name, char *resultBuf, SchemaErrorNo *errorNo)
	{
	  if (botData != DATA_NULL) {
	    *errorNo = SCHEMA_RESULT_READY;
	    *(uint16_t*)resultBuf = botData;
	    botData = DATA_NULL;
	    return SUCCESS;
	  } else {
	    photoBot = resultBuf;
	    *(uint16_t*)photoBot = 0xffff;
	    *errorNo = SCHEMA_ERROR;
#ifdef PLATFORM_MICA2DOT
		if (call TaosCh0.getData() != SUCCESS)
	      return FAIL;
#else
		return FAIL;
#endif
	    *errorNo = SCHEMA_RESULT_PENDING;
	    return SUCCESS;
	  }
	}

#ifdef PLATFORM_MICA2DOT
	async event result_t TaosCh0.dataReady(uint16_t data)
	{
	  botData = ((data >> 8) & 0xFF);
	  topData = (data & 0xFF);
	  call TaosCh1.getData();
	  return SUCCESS;
	}


	async event result_t TaosCh1.dataReady(uint16_t data)
	{
	  botData += (((data >> 8) & 0xFF) << 8);
	  topData +=  ((data & 0xFF) << 8);
	  if (photoBot != NULL)
	    {
	      *(uint16_t *)photoBot = botData;
	      call TaosBotAttr.getAttrDone("taosbot", photoBot, SCHEMA_RESULT_READY);
	      photoBot = NULL;
	    }
	  if (photoTop != NULL)
	    {
	       *(uint16_t *)photoTop = topData;
	      call TaosTopAttr.getAttrDone("taostop", photoTop, SCHEMA_RESULT_READY);
	      photoTop = NULL;
	    }
	  return SUCCESS;
	}
#endif

	event result_t TaosBotAttr.setAttr(char *name, char *attrVal)
	{
		return FAIL;
	}

	event result_t TaosTopAttr.startAttr()
	{
		if (started)
			return call TaosTopAttr.startAttrDone();
		topData = DATA_NULL;
		botData = DATA_NULL;

		photoTopStarting = TRUE;
		if (photoBotStarting)
			return SUCCESS;
#ifdef PLATFORM_MICA2DOT
		return call SensorControl.start();
#else
		return SUCCESS;
#endif
	}

	event result_t TaosTopAttr.getAttr(char *name, char *resultBuf, SchemaErrorNo *errorNo)
	{
	  if (topData != DATA_NULL) {
	    *errorNo = SCHEMA_RESULT_READY;
	    *(uint16_t*)resultBuf = topData;
	    topData = DATA_NULL;
	    return SUCCESS;
	  } else {
	    photoTop = resultBuf;
	    *(uint16_t*)photoTop = 0xffff;
	    *errorNo = SCHEMA_ERROR;
#ifndef PLATFORM_MICA2DOT
		return FAIL;
#else
		if (call TaosCh0.getData() != SUCCESS)
	      return FAIL;
#endif

	    *errorNo = SCHEMA_RESULT_PENDING;
	    return SUCCESS;
	  }
	}

	event result_t TaosTopAttr.setAttr(char *name, char *attrVal)
	{
		return FAIL;
	}
}
