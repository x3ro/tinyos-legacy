// $Id: Command.nc,v 1.3 2004/03/09 18:30:08 idgay Exp $

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
 * Date:     6/28/2002
 *
 */

/**
 * @author Wei Hong
 * @author Intel Research Berkeley Lab
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
		struct CommandMsg *cmsg;

#if 0
		if (commandMsgPending)
			return FAIL;
		commandMsgPending = TRUE;
#endif
		//msgCopy = *msg;
		cmsg = (struct CommandMsg *)msg->data;

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
		if (addCmdPending)
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
		cmd->name = commandName;
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
