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
 * Date:     6/28/2002
 *
 */

module Command 
{
	provides
	{
		interface StdControl;
		interface CommandRegister as Cmd[uint8_t id];
		interface CommandUse;
	}
}
implementation 
{
	CommandDescs	commandDescs;
	bool			addCmdPending;
	bool			commandMsgPending;

	command result_t StdControl.init()
	{
		commandDescs.numCmds = 0;
		addCmdPending = FALSE;
		commandMsgPending = FALSE;
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

/* Return a pointer to the  descriptor for the specified command,
   or NULL if the command does not exist
*/
	command CommandDescPtr CommandUse.getCommand(char *cmd)
	{
		// read numCmds into local variable to reduce window of race condition
		short numCmds = commandDescs.numCmds;
		short i;
		for (i = 0; i < numCmds; i++)
		{
			if (strcasecmp(commandDescs.commandDesc[i].name, cmd) == 0)
				return &commandDescs.commandDesc[i];
		}
		return NULL;
	}

/* Return a pointer to the descriptor for the specified command index,
   or NULL if the index is not valid
*/
	command CommandDescPtr CommandUse.getCommandById(uint8_t id) 
	{
		short numCmds = commandDescs.numCmds;
		if (id >= numCmds)
			return NULL;
		return &commandDescs.commandDesc[(int)id];
	}

	command CommandDescsPtr CommandUse.getCommands()
	{
		return &commandDescs;
	}

	command uint8_t CommandUse.numCommands()
	{
		return commandDescs.numCmds;
	}

	/* Invoke the specified command index with the specified params 
	   Split phase operation.  Completion event is commandDone
	   ParamVals is returned with result field filled in.
	*/
	command result_t CommandUse.invoke(char *commandName,
					char *resultBuf,
					SchemaErrorNo *errorNo,
					ParamVals *params)
	{
		CommandDescPtr commandDesc = call CommandUse.getCommand(commandName);
		if (commandDesc == NULL || commandDesc->params.numParams != params->numParams)
			return FAIL;
		if (signal Cmd.commandFunc[commandDesc->id](commandName, resultBuf, errorNo, params) != SUCCESS)
			return FAIL;
		if (*errorNo == SCHEMA_ERROR)
			return FAIL;
		return SUCCESS;
	}

	/* Invoke the specified command index with the specified params 
	   Split phase operation.  Completion event is commandDone
	   ParamVals is returned with result field filled in.
	*/
	command result_t CommandUse.invokeById(uint8_t commandId,
					char *resultBuf,
					SchemaErrorNo *errorNo,
					ParamVals *params)
	{
		CommandDescPtr commandDesc = call CommandUse.getCommandById(commandId);
		if (commandDesc == NULL || commandDesc->params.numParams != params->numParams)
			return FAIL;
		if (signal Cmd.commandFunc[commandDesc->id](commandDesc->name, resultBuf, errorNo, params) != SUCCESS)
			return FAIL;
		if (*errorNo == SCHEMA_ERROR)
			return FAIL;
		return SUCCESS;
	}

	/* parse command invoke message, then invoke command */
	command result_t CommandUse.invokeBuffer(char *ptr, char *resultBuf, SchemaErrorNo *errorNo)
	{
		char *commandName;
		short i;
		ParamVals paramVals;
		CommandDescPtr cmd;

		commandName = ptr;
		cmd = call CommandUse.getCommand(commandName);
		if (cmd == NULL) { //unknown command...
		    return FAIL;
		}
		for (i = 0, ptr += strlen(commandName) + 1; i < cmd->params.numParams; i++)
		{
		        paramVals.paramDataPtr[i] = ptr;
			ptr += lengthOf(cmd->params.params[i], ptr);
		}
		paramVals.numParams = cmd->params.numParams;
		return call CommandUse.invoke(commandName, resultBuf, errorNo, &paramVals);
	}

	/* parse command invoke message, then invoke command */
	command result_t CommandUse.invokeMsg(TOS_MsgPtr msg, char *resultBuf, SchemaErrorNo *errorNo)
	{
		uint16_t nodeid;
		static TOS_Msg msgCopy;
		struct CommandMsg *cmsg;

#if 0
		if (commandMsgPending)
			return FAIL;
		commandMsgPending = TRUE;
#endif
		msgCopy = *msg;
		cmsg = (struct CommandMsg *)msgCopy.data;

		nodeid = cmsg->nodeid;
		if (nodeid == TOS_BCAST_ADDR || nodeid == TOS_LOCAL_ADDRESS)
		{
		        return call CommandUse.invokeBuffer(cmsg->data, resultBuf, errorNo);
		}
#if 0
		commandMsgPending = FALSE;
#endif
		return SUCCESS;
	}

	/* Add a new command to the schema with the specified parameters and procedure pointer */
	command result_t Cmd.registerCommand[uint8_t id](char *commandName, 
											  TOSType retType,
											  uint8_t retLen,
											  ParamList *params)
	{
		short cmdIdx;
		bool cmdExists = FALSE;
		CommandDesc *cmd;
		short len;
		if (params->numParams > MAX_PARAMS)
			return FAIL;
		if (addCmdPending || strlen(commandName) > MAX_CMD_NAME_LEN)
			return FAIL;
		else
			addCmdPending = TRUE;
		// replace command definition if one with same name exists
		for (cmdIdx = 0; cmdIdx < commandDescs.numCmds; cmdIdx++)
			if (strcasecmp(commandDescs.commandDesc[cmdIdx].name, commandName) == 0)
			{
				cmdExists = TRUE;
				break;
			}
		if (!cmdExists)
		{
			if (commandDescs.numCmds < MAX_COMMANDS)
				commandDescs.numCmds++;
			else
			{
				addCmdPending = FALSE;
				return FAIL;
			}
		}
		cmd = &commandDescs.commandDesc[cmdIdx];
		cmd->idx = cmdIdx;
		cmd->id = id;
		strcpy(cmd->name, commandName);
		cmd->retType = retType;
		len = sizeOf(retType);
		if (len < 0)
			cmd->retLen = retLen; // only use retLen for variable-length types
		else
			cmd->retLen = (uint8_t)len;
		cmd->params = *params;
		addCmdPending = FALSE;
		return SUCCESS;
	}

	command result_t Cmd.commandDone[uint8_t id](char *commandName, char *resultBuf, SchemaErrorNo errorNo)
	{
		signal CommandUse.commandDone(commandName, resultBuf, errorNo);
		return SUCCESS;
	}

	default event result_t Cmd.commandFunc[uint8_t id](char *commandName, char *resultBuf, SchemaErrorNo *errorNo, ParamVals *params)
	{
		return SUCCESS;
	}
}
