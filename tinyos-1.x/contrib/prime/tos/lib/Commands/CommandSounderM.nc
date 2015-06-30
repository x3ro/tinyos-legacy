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
 * Date:     7/15/2002
 *
 */

// register command for turning sounder on for a peroid of time
// SetSound(uint16_t n): turn sounder on for n milliseconds
module CommandSounderM
{
	provides interface StdControl;
	uses
	{
		interface CommandRegister as SetSound;
		interface StdControl as SounderControl;
		interface Timer as Clock1;
		interface StdControl as TimerControl;
	}
}
implementation
{
	bool commandPending;
	command result_t StdControl.init()
	{
		ParamList paramList;
		call SounderControl.init();
		call TimerControl.init();
		setParamList(&paramList, 1, INT16);
		if (call SetSound.registerCommand("SetSnd", VOID, 0, &paramList) != SUCCESS)
			return FAIL;
		commandPending = FALSE;
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

	event result_t SetSound.commandFunc(char *commandName, char *resultBuf, SchemaErrorNo *errorNo, ParamVals *params)
	{
		int16_t arg = *(uint16_t*)(params->paramDataPtr[0]);
		*errorNo = SCHEMA_RESULT_READY;
		if (commandPending)
			return FAIL;
		commandPending = TRUE;
		call Clock1.start(TIMER_ONE_SHOT, arg);
		return call SounderControl.start();
	}

	event result_t Clock1.fired()
	{
	  result_t ret = call SounderControl.stop();
		commandPending = FALSE;
		return ret;
	}
}
