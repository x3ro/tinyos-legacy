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
 * Date:     8/6/2002
 *
 */
// component to expose Accelerometer readings as an attribute
module AttrAccelM
{
	provides interface StdControl;
	uses 
	{
		interface ADC as AccelX;
		interface ADC as AccelY;
		interface StdControl as AccelControl;
		interface AttrRegister as AttrAccelX;
		interface AttrRegister as AttrAccelY;
	}
}
implementation
{
	char *resultX;
	char *attrNameX;
	char *resultY;
	char *attrNameY;

	command result_t StdControl.init()
	{
		if (call AttrAccelX.registerAttr("accel_x", UINT16, 2) != SUCCESS)
			return FAIL;
		if (call AttrAccelY.registerAttr("accel_y", UINT16, 2) != SUCCESS)
			return FAIL;
		return call AccelControl.init();
	}

	command result_t StdControl.start()
	{
		return SUCCESS;
	}

	command result_t StdControl.stop()
	{
		return call AccelControl.stop();
	}

	event result_t AttrAccelX.startAttr()
	{
		result_t res = call AccelControl.start();
		call AttrAccelX.startAttrDone();
		return res;
	}

	event result_t AttrAccelX.getAttr(char *name, char *resultBuf, SchemaErrorNo *errorNo)
	{
		resultX = resultBuf;
		attrNameX = name;
		if (call AccelX.getData() != SUCCESS)
			return FAIL;
		*errorNo = SCHEMA_RESULT_PENDING;
		return SUCCESS;
	}

	event result_t AttrAccelX.setAttr(char *name, char *attrVal)
	{
		return FAIL;
	}

	event result_t AccelX.dataReady(uint16_t data)
	{
		*(uint16_t*)resultX = data;
		call AttrAccelX.getAttrDone(attrNameX, resultX, SCHEMA_RESULT_READY);
		return SUCCESS;
	}

	event result_t AttrAccelY.startAttr()
	{
		result_t res = call AccelControl.start();
		call AttrAccelY.startAttrDone();
		return res;
	}

	event result_t AttrAccelY.getAttr(char *name, char *resultBuf, SchemaErrorNo *errorNo)
	{
		resultY = resultBuf;
		attrNameY = name;
		if (call AccelY.getData() != SUCCESS)
			return FAIL;
		*errorNo = SCHEMA_RESULT_PENDING;
		return SUCCESS;
	}

	event result_t AttrAccelY.setAttr(char *name, char *attrVal)
	{
		return FAIL;
	}

	event result_t AccelY.dataReady(uint16_t data)
	{
		*(uint16_t*)resultY = data;
		call AttrAccelY.getAttrDone(attrNameY, resultY, SCHEMA_RESULT_READY);
		return SUCCESS;
	}
}
