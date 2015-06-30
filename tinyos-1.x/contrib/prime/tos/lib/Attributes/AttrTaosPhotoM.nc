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
// component to expose Photo sensor reading as an attribute
module AttrTaosPhotoM
{
	provides interface StdControl;
	uses 
	{
		interface AttrRegister as TaosBotAttr;
		interface AttrRegister as TaosTopAttr;
		interface ADC as TaosCh0;
		interface ADC as TaosCh1;
		interface SplitControl as SensorControl;
	}
}
implementation
{
	char *photoBot;
	char *photoTop;
	bool started;
	bool photoBotStarting;
	bool photoTopStarting;

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
	  return call SensorControl.stop();
	}

	event result_t SensorControl.stopDone()
	{
		started = FALSE;
		return SUCCESS;
	}

	event result_t TaosBotAttr.startAttr()
	{
		if (started)
			return call TaosBotAttr.startAttrDone();
		photoBotStarting = TRUE;
		if (photoTopStarting)
			return SUCCESS;
		return call SensorControl.start();
	}

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

	event result_t TaosBotAttr.getAttr(char *name, char *resultBuf, SchemaErrorNo *errorNo)
	{
		photoBot = resultBuf;
		*(uint16_t*)photoBot = 0xffff;
		*errorNo = SCHEMA_ERROR;
		if (call TaosCh0.getData() != SUCCESS)
			return FAIL;
		*errorNo = SCHEMA_RESULT_PENDING;
		return SUCCESS;
	}

	event result_t TaosCh0.dataReady(uint16_t data)
	{
		if (photoBot != NULL)
			*(uint16_t*)photoBot = ((data >> 8) & 0xFF);
		if (photoTop != NULL)
			*(uint16_t*)photoTop = (data & 0xFF);
		call TaosCh1.getData();
		return SUCCESS;
	}

	event result_t TaosCh1.dataReady(uint16_t data)
	{
		if (photoBot != NULL)
			*(uint16_t*)photoBot += (((data >> 8) & 0xFF) << 8);
		if (photoTop != NULL)
			*(uint16_t*)photoTop += ((data & 0xFF) << 8);
		if (photoBot != NULL)
		{
			call TaosBotAttr.getAttrDone("taosbot", photoBot, SCHEMA_RESULT_READY);
			photoBot = NULL;
		}
		if (photoTop != NULL)
		{
			call TaosTopAttr.getAttrDone("taostop", photoTop, SCHEMA_RESULT_READY);
			photoTop = NULL;
		}
		return SUCCESS;
	}


	event result_t TaosBotAttr.setAttr(char *name, char *attrVal)
	{
		return FAIL;
	}

	event result_t TaosTopAttr.startAttr()
	{
		if (started)
			return call TaosTopAttr.startAttrDone();
		photoTopStarting = TRUE;
		if (photoBotStarting)
			return SUCCESS;
		return call SensorControl.start();
	}

	event result_t TaosTopAttr.getAttr(char *name, char *resultBuf, SchemaErrorNo *errorNo)
	{
		photoTop = resultBuf;
		*(uint16_t*)photoTop = 0xffff;
		*errorNo = SCHEMA_ERROR;
		if (call TaosCh0.getData() != SUCCESS)
			return FAIL;
		*errorNo = SCHEMA_RESULT_PENDING;
		return SUCCESS;
	}

	event result_t TaosTopAttr.setAttr(char *name, char *attrVal)
	{
		return FAIL;
	}
}
