// $Id: CommandLedsM.nc,v 1.1.1.1 2007/11/05 19:09:07 jpolastre Exp $

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
 * Date:     7/1/2002
 *
 */

// register commands SetLed_R, SetLed_G, SetLed_Y for controling the
// red, green and yellow LEDs.  all commands take 1 argument:
// 0 turns LED off, 1 turns LED on, 2 toggles LED


/**
 * @author Wei Hong
 * @author Intel Research Berkeley Lab
 */
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
