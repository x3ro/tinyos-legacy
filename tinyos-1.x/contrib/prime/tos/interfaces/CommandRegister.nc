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
 * Date:     6/27/2002
 *
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
      @param name The name of the command to register
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
