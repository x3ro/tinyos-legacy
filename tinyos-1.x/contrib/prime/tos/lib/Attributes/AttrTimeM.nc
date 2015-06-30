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
 * Date:     3/24/2003
 *
 */
// component to expose logical time as attributes
module AttrTimeM
{
	provides interface StdControl;
	uses 
	{
		interface Time;
		interface AttrRegister as TimeLowAttr;
		interface AttrRegister as TimeHighAttr;
	}
}
implementation
{
	command result_t StdControl.init()
	{
		if (call TimeLowAttr.registerAttr("timelo", UINT32, 4) != SUCCESS)
			return FAIL;
		if (call TimeHighAttr.registerAttr("timehi", UINT32, 4) != SUCCESS)
			return FAIL;
		return SUCCESS;
	}

	command result_t StdControl.start()
	{
		return SUCCESS;
	}

	command result_t StdControl.stop()
	{
		return SUCCESS;
	}

	event result_t TimeLowAttr.startAttr()
	{
		return call TimeLowAttr.startAttrDone();
	}

	event result_t TimeLowAttr.getAttr(char *name, char *resultBuf, SchemaErrorNo *errorNo)
	{
		*(uint32_t*)resultBuf = call Time.getLow32();
		*errorNo = SCHEMA_RESULT_READY;
		return SUCCESS;
	}

	event result_t TimeLowAttr.setAttr(char *name, char *attrVal)
	{
		return FAIL;
	}

	event result_t TimeHighAttr.startAttr()
	{
		return call TimeHighAttr.startAttrDone();
	}

	event result_t TimeHighAttr.getAttr(char *name, char *resultBuf, SchemaErrorNo *errorNo)
	{
		*(uint32_t*)resultBuf = call Time.getHigh32();
		*errorNo = SCHEMA_RESULT_READY;
		return SUCCESS;
	}

	event result_t TimeHighAttr.setAttr(char *name, char *attrVal)
	{
		return FAIL;
	}
}
