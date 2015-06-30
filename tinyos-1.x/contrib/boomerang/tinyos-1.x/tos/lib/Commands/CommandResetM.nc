// $Id: CommandResetM.nc,v 1.1.1.1 2007/11/05 19:09:07 jpolastre Exp $

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

// register command for resetting motes


/**
 * @author Wei Hong
 * @author Intel Research Berkeley Lab
 */
module CommandResetM
{
	provides interface StdControl;
	uses
	{
		interface CommandRegister as ResetCmd;
		interface Reset;
		interface Leds;
		interface Timer;
	}
}
implementation
{
  bool mReady;
 
	command result_t StdControl.init()
	{
		ParamList paramList;
		paramList.numParams = 0;
		mReady = FALSE;
		if (call ResetCmd.registerCommand("Reset", VOID, 0, &paramList) != SUCCESS)
			return FAIL;
		return SUCCESS;
	}

	command result_t StdControl.start()
	{
	  //start a timer -- don't reset if this hasn't fired yet
	  // provides a simple way to prevent neverending resets...
	  call Timer.start(TIMER_ONE_SHOT, 1024);
	  return SUCCESS;
	  
	}
	
	event result_t Timer.fired() {
	  mReady = TRUE;
	  return SUCCESS;
	}
	
	command result_t StdControl.stop()
	{
		return SUCCESS;
	}

	event result_t ResetCmd.commandFunc(char *commandName, char *resultBuf, SchemaErrorNo *errorNo, ParamVals *params)
	{
		*errorNo = SCHEMA_RESULT_READY;
		if (mReady) {
		  call Leds.redOn();
		  call Leds.greenOn();
		  call Leds.yellowOn();
		  call Reset.reset();
		}
		return SUCCESS;
	}
}
