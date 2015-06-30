// $Id: CommandUse.nc,v 1.1.1.1 2007/11/05 19:09:02 jpolastre Exp $

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
 * Date:     6/27/2002
 *
 */

/**
 * @author Wei Hong
 * @author Intel Research Berkeley Lab
 */


includes SchemaType;
includes Command;
includes AM;
/** Interface for using Commands.  Commands provide a generic mechanism for registering
    and executing named commands via AM messages or a local interface.
    <p>
    See lib/Commands/... for examples of components that register commands.
    <p>
    See interfaces/Command.h for the data structures used in this interface 
    <p>
    Implemented by lib/Command.td
    <p>
    @author Wei Hong (wei.hong@intel-research.net)
*/
interface CommandUse
{
  /** Get a descriptor for the specified command
      @param name The (8 byte or shorted, null-terminated) name for the command of interest.
      @return A pointer to the command descriptior, or NULL if no such command exists.
  */
  command CommandDescPtr getCommand(char *name);
  /** Get a descriptor for a specified command id
      @param idx The (0-based) index of the command of interest
      @return A pointer to the command descriptor, or NULL if no such command exists.
  */
  command CommandDescPtr getCommandById(uint8_t idx);
  
  /** @return The number of commands currently registered with the system */
  command uint8_t numCommands();

  /** @return A list of all the commands in the system */
  command CommandDescsPtr getCommands();

  /** Invoke the specified command by name, with the specified parameters.
     Write the results into the specified buffer.
     @param commandName The command to invoke.
     @param resultBuf The buffer to write results into (must be at least sizeOf(CommandDesc.retType) bytes long)
     @param errorNo (on return) The result code (may signal a split-phase invocation, for which a commandDone event will be fired later)
                    See SchemaType.h for a list of possible result codes
     @param params The parameters to this funtion.
  */
  command result_t invoke(char *commandName, char *resultBuf, SchemaErrorNo *errorNo, ParamVals *params);

  command result_t invokeById(uint8_t commandId, char *resultBuf, SchemaErrorNo *errorNo, ParamVals *params);

  /** Given a msg represent a command invocation, invoke the appropriate command, writing results to
      resultBuf. See invoke(...) above
      @param msg The command message.  The format of this message is a packed array representing the name of
                 the command, followed by a packed list of parameters.  See java/net/tinyos/tinydb/CommandMsgs.java
		 for an example of a Java program that invokes a command.
      @param resultBuf The result buffer to write results into 
      @param errorNo (on return)The result code
  */
  command result_t invokeMsg(TOS_MsgPtr msg, char *resultBuf, SchemaErrorNo *errorNo);

  /** Given a buffer represent a command invocation (in the format used inside
      command messages), invoke the appropriate command, writing results to
      resultBuf. See invoke(...) above
      @param buffer The command description.  The format of this buffer is a packed array representing the name of
                 the command, followed by a packed list of parameters.  See java/net/tinyos/tinydb/CommandMsgs.java
		 for an example of a Java program that fills this buffer.
		 This buffer must remain valid for the duration of command execution.
      @param resultBuf The result buffer to write results into 
      @param errorNo (on return)The result code
  */
  command result_t invokeBuffer(char *buffer, char *resultBuf, SchemaErrorNo *errorNo);
  
  /** Signalled when a command invocation is complete 
      @param commandName The command that was completed
      @param resultBuf The buffer where the results were written
      @param errorNo The return code from the invocation.
  */
  event result_t commandDone(char *commandName, char *resultBuf, SchemaErrorNo errorNo);
}
