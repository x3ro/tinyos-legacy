// $Id: CommandRegister.nc,v 1.3 2004/03/09 18:30:09 idgay Exp $

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

/** The interface for registering commands.
    <p>
    See lib/Commands/... for examples of components that register commands.
    <p>
    See interfaces/Command.h for the data structures used in this interface 
    <p>
    Implemented by lib/Command.td
    <p>
    @author Wei Hong (wei.hong@intel-research.net)
*/
interface CommandRegister
{
  /** Register a command with the specified name, return type, return length, and parameters.
      @param name The name of the command to register. Must be in global
        storage.
      @param retType The type of the command (see SchemaType.h) 
      @param retLen The length (in bytes) of the command
      @param paramList The parameters to this command (see Command.h for the def of paramList)
  */
  command result_t registerCommand(char *name, TOSType retType, uint8_t retLen, ParamList *paramList);

  /** Called by Command.td when a specified command is invoked by the user.  The implementer must
      actually carry out the command.
      @param The name of the command that was invoked
      @param The buffer where the command result should be written
      @param An error code (may be SCHEMA_RESULT_PENDING, in which case commandDone must be called at some time in
       the future.)
  */
  event result_t commandFunc(char *commandName, char *resultBuf, SchemaErrorNo *errorNo, ParamVals *params);

  /** Should be called when a specified command invocation has completed
   @param The name of the command that completed
   @param resultBuf The buffer where the result was written
   @param errorNo The result code for the command
  */
  command result_t commandDone(char *commandName, char *resultBuf, SchemaErrorNo errorNo);
}
