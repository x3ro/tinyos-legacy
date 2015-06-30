/* "Copyright (c) 2000-2002 The Regents of the University of California.  
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
 */

// Authors: Cory Sharp
// $Id: CommandInterpreterM.nc,v 1.1 2003/06/02 12:27:47 dlkiskis Exp $

includes Command;

module CommandInterpreterM
{
  uses
  {
    interface CommandUse as CommandInvoke;
    interface RoutingReceive;
    interface ReceiveMsg;
    interface Leds;
  }
}
implementation
{
  event TOS_MsgPtr ReceiveMsg.receive(TOS_MsgPtr m)
  {
 	char resultBfr;
	SchemaErrorNo errorNo;
	call CommandInvoke.invokeMsg(m, &resultBfr, &errorNo);
	return m;
  }

  event TOS_MsgPtr RoutingReceive.receive(TOS_MsgPtr m)
  {
 	char resultBfr;
	SchemaErrorNo errorNo;
	call CommandInvoke.invokeMsg(m, &resultBfr, &errorNo);
	return m;
  }

  event result_t CommandInvoke.commandDone(char *commandName, char *resultBuf, SchemaErrorNo errorNo){
	return SUCCESS;
  }

}



