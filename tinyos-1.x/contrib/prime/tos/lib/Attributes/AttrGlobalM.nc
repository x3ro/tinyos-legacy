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
 * Date:     7/1/2002
 *
 */
includes AM;

// component to expose certain global variables as attributes
module AttrGlobalM
{
	provides interface StdControl;
	uses
	{
		interface AttrRegister as NodeIdAttr;
		interface AttrRegister as GroupAttr;
	}
}
implementation
{
	command result_t StdControl.init()
	{
		if (call NodeIdAttr.registerAttr("nodeid", UINT16, 2) != SUCCESS)
			return FAIL;
		if (call GroupAttr.registerAttr("group", UINT8, 1) != SUCCESS)
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

	event result_t NodeIdAttr.startAttr()
	{
		return call NodeIdAttr.startAttrDone();
	}

	event result_t NodeIdAttr.getAttr(char *name, char *resultBuf, SchemaErrorNo *errorNo)
	{
		*errorNo = SCHEMA_RESULT_READY;
		*(uint16_t*)resultBuf = TOS_LOCAL_ADDRESS;
		return SUCCESS;
	}

	event result_t NodeIdAttr.setAttr(char *name, char *resultBuf)
	{
		TOS_LOCAL_ADDRESS = *(uint16_t*)resultBuf;
		return SUCCESS;
	}

	event result_t GroupAttr.startAttr()
	{
		return call GroupAttr.startAttrDone();
	}

	event result_t GroupAttr.getAttr(char *name, char *resultBuf, SchemaErrorNo *errorNo)
	{
		*errorNo = SCHEMA_RESULT_READY;
		*(uint8_t*)resultBuf = TOS_AM_GROUP;
		return SUCCESS;
	}

	event result_t GroupAttr.setAttr(char *name, char *resultBuf)
	{
		TOS_AM_GROUP = *(uint8_t*)resultBuf;
		return SUCCESS;
	}
}
