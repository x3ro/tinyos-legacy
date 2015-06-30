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

// register commands SetLed_R, SetLed_G, SetLed_Y for controling the
// red, green and yellow LEDs.  all commands take 1 argument:
// 0 turns LED off, 1 turns LED on, 2 toggles LED
module CommandLedsM
{
	provides interface StdControl;
	uses
	{
		interface CommandRegister as RedLedCmd;
		interface CommandRegister as GreenLedCmd;
		interface CommandRegister as YellowLedCmd;
		interface Leds;
	}
}
implementation
{
	command result_t StdControl.init()
	{
		ParamList paramList;
		call Leds.init();
		setParamList(&paramList, 1, UINT8);
		if (call RedLedCmd.registerCommand("SetLedR", VOID, 0, &paramList) != SUCCESS)
			return FAIL;
		if (call GreenLedCmd.registerCommand("SetLedG", VOID, 0, &paramList) != SUCCESS)
			return FAIL;
		if (call YellowLedCmd.registerCommand("SetLedY", VOID, 0, &paramList) != SUCCESS)
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

	event result_t RedLedCmd.commandFunc(char *commandName, char *resultBuf, SchemaErrorNo *errorNo, ParamVals *params)
	{
		uint8_t arg = *(uint8_t*)(params->paramDataPtr[0]);

		*errorNo = SCHEMA_RESULT_READY;
		if (arg == 0)
		{
			if (call Leds.redOff() != SUCCESS)
				return FAIL;
		}
		else if (arg == 1)
		{
			if (call Leds.redOn() != SUCCESS)
				return FAIL;
		}
		else
		{
			if (call Leds.redToggle() != SUCCESS)
				return FAIL;
		}
		return SUCCESS;
	}

	event result_t GreenLedCmd.commandFunc(char *commandName, char *resultBuf, SchemaErrorNo *errorNo, ParamVals *params)
	{
		uint8_t arg = *(uint8_t*)(params->paramDataPtr[0]);

		*errorNo = SCHEMA_RESULT_READY;
		if (arg == 0)
		{
			if (call Leds.greenOff() != SUCCESS)
				return FAIL;
		}
		else if (arg == 1)
		{
			if (call Leds.greenOn() != SUCCESS)
				return FAIL;
		}
		else
		{
			if (call Leds.greenToggle() != SUCCESS)
				return FAIL;
		}
		return SUCCESS;
	}

	event result_t YellowLedCmd.commandFunc(char *commandName, char *resultBuf, SchemaErrorNo *errorNo, ParamVals *params)
	{
		uint8_t arg = *(uint8_t*)(params->paramDataPtr[0]);

		*errorNo = SCHEMA_RESULT_READY;
		if (arg == 0)
		{
			if (call Leds.yellowOff() != SUCCESS)
				return FAIL;
		}
		else if (arg == 1)
		{
			if (call Leds.yellowOn() != SUCCESS)
				return FAIL;
		}
		else
		{
			if (call Leds.yellowToggle() != SUCCESS)
				return FAIL;
		}
		return SUCCESS;
	}
}
