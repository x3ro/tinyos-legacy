// $Id: CommandSounderM.nc,v 1.3 2003/10/07 21:46:17 idgay Exp $

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
 * Date:     7/15/2002
 *
 */

// register command for turning sounder on for a peroid of time
// SetSound(uint16_t n): turn sounder on for n milliseconds


/**
 * @author Wei Hong
 * @author Intel Research Berkeley Lab
 */
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
