/*									tab:4
 * 
 *  ===================================================================================
 *
 *  IMPORTANT:  READ BEFORE DOWNLOADING, COPYING, INSTALLING OR USING.  
 *  By downloading, copying, installing or using the software you agree to this license.
 *  If you do not agree to this license, do not download, install, copy or use the software.
 *
 *  Intel Open Source License 
 *
 *  Copyright (c) 1996-2000 Intel Corporation 
 *  All rights reserved. 
 *  Redistribution and use in source and binary forms, with or without modification,
 *  are permitted provided that the following conditions are met: 
 * 
 *	Redistributions of source code must retain the above copyright notice, this 
 *  list of conditions and the following disclaimer. 
 *	Redistributions in binary form must reproduce the above copyright notice, this
 *  list of conditions and the following disclaimer in the documentation and/or other 
 *  materials provided with the distribution. 
 *	Neither the name of the Intel Corporation nor the names of its contributors may 
 *  be used to endorse or promote products derived from this software without specific 
 *  prior written permission.
 *  
 *  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS ``AS IS'' 
 *  AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 *  WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. 
 *  IN NO EVENT SHALL THE INTEL OR ITS  CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 *  INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
 *  TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; 
 *  OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER 
 *  IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) 
 *  ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE 
 *  POSSIBILITY OF SUCH DAMAGE.
 * 
 * =============================================================================
 * 
 * Authors:  Wei Hong
 *           Intel Research Berkeley Lab
 * Date:     5/3/2002
 *
 */

#include <string.h>
#include <stdarg.h>
#include "SCHEMA.h"
#include "SchemaAPI.h"

#define TOS_FRAME_TYPE SCHEMA_frame
TOS_FRAME_BEGIN(SCHEMA_frame) {
	AttrDescs		attrDescs;
	CommandDescs	commandDescs;
	CommandCallInfo	commandCallInfo[MAX_CONCURRENT_COMMANDS];
	bool			addAttrPending;
	bool			addCmdPending;
	bool			commandMsgPending;
	TOS_Msg			msg;
} 
TOS_FRAME_END(SCHEMA_frame);

/* Initialize the schema component */
char TOS_COMMAND(SCHEMA_INIT)(){ 
	// XXX read attribute and command descriptors from EEPROM
	VAR(attrDescs).numAttrs = 0;
	VAR(commandDescs).numCmds = 0;
	VAR(addAttrPending) = FALSE;
	VAR(addCmdPending) = FALSE;
	VAR(commandMsgPending) = FALSE;
	memset(&VAR(commandCallInfo)[0], 0, sizeof(VAR(commandCallInfo)));
  	return TOS_Success;
}

// returns descriptor of all attributes
AttrDescsPtr TOS_COMMAND(SCHEMA_GET_ATTRS)(void)
{
	return &VAR(attrDescs);
}

/* Return a pointer to the attribute descriptor with the specified
   name, or NULL if no such attribute exists.
*/
AttrDescPtr TOS_COMMAND(SCHEMA_GET_ATTR)(char *attr) 
{
	// read numAttrs to local variable to reduce the window of race condition, XXX
	short numAttrs = VAR(attrDescs).numAttrs;
	short i;
	for (i = 0; i < numAttrs; i++)
	{
		if (strcmp(VAR(attrDescs).attrDesc[i].name, attr) == 0)
			return &VAR(attrDescs.attrDesc[i]);
	}
	return NULL;
}

/* Return a pointer to the attribute descriptor with the specified
   index, or NULL if no such attribute exists. */
AttrDescPtr TOS_COMMAND(SCHEMA_GET_ATTR_BY_ID)(int1 attrIdx)
{
	short numAttrs = VAR(attrDescs).numAttrs;
	if (attrIdx < 0 || attrIdx >= numAttrs)
		return NULL;
	return &VAR(attrDescs).attrDesc[(short)attrIdx];
}

/* Add the specified attribute to the schema.  Copies the attribute
   into the schema (does not store the passed in reference.)

   If the attribute already exists, replaces it with the new
   descriptor.
*/

char TOS_COMMAND(SCHEMA_ADD_ATTR)(char *attrName, 
								TOSType type, 
								int1 attrLen,
								func_ptr getFunc,
								func_ptr setFunc)
{
	char cmdName[MAX_CMD_NAME_LEN + 1];
	short attrIdx;
	AttrDescPtr attr;
	bool attrExists = FALSE;
	CommandDescPtr cmd;
	if (VAR(addAttrPending) || strlen(attrName) > MAX_ATTR_NAME_LEN)
		return TOS_Failure;
	else
		VAR(addAttrPending) = TRUE;
	// XXX should probably turn this into a task
	// if attribute already exists, replace it with new attr definition
	for (attrIdx = 0; attrIdx < VAR(attrDescs).numAttrs; attrIdx++)
		if (strcmp(VAR(attrDescs).attrDesc[(int)attrIdx].name, attrName) == 0)
		{
			attrExists = TRUE;
			break;
		}
	if (!attrExists)
	{
		if (VAR(attrDescs).numAttrs < MAX_ATTRS)
			VAR(attrDescs).numAttrs++;
		else
		{
			VAR(addAttrPending) = FALSE;
			return TOS_Failure;
		}
	}
	attr = &VAR(attrDescs).attrDesc[(int)attrIdx];
	attr->type = type;
	attr->idx = attrIdx;
	attr->nbytes = SIZEOF(type);
	if (attr->nbytes < 0)
		// for variable length types
		attr->nbytes = attrLen;
	attr->getFunction = getFunc;
	attr->setFunction = setFunc;
	strcpy(attr->name, attrName);
	strcpy(cmdName, "get");
	strcat(cmdName, attrName);
	// auto-generate commands to get/set attribute values
	TOS_COMMAND(SCHEMA_ADD_COMMAND)(cmdName, getFunc, type, attr->nbytes, 0);
	cmd = TOS_COMMAND(SCHEMA_GET_COMMAND)(cmdName);
	attr->getCommand = cmd->idx;
	if (setFunc != NULL)
	{
		cmdName[0] = 's';
		TOS_COMMAND(SCHEMA_ADD_COMMAND)(cmdName, setFunc, VOID, 0, 1, type);
		cmd = TOS_COMMAND(SCHEMA_GET_COMMAND)(cmdName);
		attr->getCommand = cmd->idx;
	}
	VAR(addAttrPending) = FALSE;
	return TOS_Success;
}
 

/* Return TRUE iff the specified schema attribute exists, FALSE otherwise */
bool TOS_COMMAND(SCHEMA_HAS_ATTR)(char *attr)
{
	if (TOS_CALL_COMMAND(SCHEMA_GET_ATTR)(attr) != NULL)
		return TRUE;
	return FALSE;
}
 
/* Return the number of attributes in this schema.  Attributes can be
   accessed sequentially via the SCHEMA_GET_ATTR_ID command 
*/
int1 TOS_COMMAND(SCHEMA_NUM_ATTRS)()
{
	return VAR(attrDescs).numAttrs;
}

/* Return a pointer to the  descriptor for the specified command,
   or NULL if the command does not exist
*/
CommandDescPtr TOS_COMMAND(SCHEMA_GET_COMMAND)(char *command)
{
	// read numCmds into local variable to reduce window of race condition
	short numCmds = VAR(commandDescs).numCmds;
	short i;
	for (i = 0; i < numCmds; i++)
	{
		if (strcmp(VAR(commandDescs).commandDesc[i].name, command) == 0)
			return &VAR(commandDescs).commandDesc[i];
	}
	return NULL;
}

/* Return a pointer to the descriptor for the specified command index,
   or NULL if the index is not valid
*/
CommandDescPtr TOS_COMMAND(SCHEMA_GET_COMMAND_BY_ID)(int1 commandIdx) 
{
	short numCmds = VAR(commandDescs).numCmds;
	if (commandIdx < 0 || commandIdx >= numCmds)
		return NULL;
	return &VAR(commandDescs).commandDesc[(int)commandIdx];
}

CommandDescsPtr TOS_COMMAND(SCHEMA_GET_COMMANDS)(void)
{
	return &VAR(commandDescs);
}

int1 TOS_COMMAND(SCHEMA_NUM_COMMANDS)(void)
{
	return VAR(commandDescs).numCmds;
}

CommandCallInfo *allocCommandCallInfo(void)
{
	short i;
	for (i = 0; i < MAX_CONCURRENT_COMMANDS; i++)
		if (VAR(commandCallInfo)[i].commandDesc == NULL)
			return &VAR(commandCallInfo)[i];
	return NULL;
}

char freeCommandCallInfo(CommandCallInfo *callInfo)
{
	memset(callInfo, 0, sizeof(*callInfo));
	return TOS_Success;
}

char TOS_COMMAND(SCHEMA_END_COMMAND)(CommandCallInfo *callInfo)
{
	freeCommandCallInfo(callInfo);
	return TOS_Success;
}

void callFunction(func_ptr func, ParamVals *params, CommandCallInfo *callInfo)
{
	switch (params->numParams) {
	case 0:
		(*func)(callInfo);
		break;
	case 1:
		(*func)(params->paramDataPtr[0], callInfo);
		break;
	case 2:
		(*func)(params->paramDataPtr[0], params->paramDataPtr[1], callInfo);
		break;
	case 3:
		(*func)(params->paramDataPtr[0], params->paramDataPtr[1], params->paramDataPtr[2], callInfo);
		break;
	case 4:
		(*func)(params->paramDataPtr[0], params->paramDataPtr[1], params->paramDataPtr[2], params->paramDataPtr[3], callInfo);
		break;
	}
}

/* Invoke the specified command index with the specified params 
   Split phase operation.  Completion event is COMMAND_COMPLETE.
   ParamVals is returned with result field filled in.
*/
char TOS_COMMAND(SCHEMA_INVOKE_COMMAND)(CommandDescPtr commandDesc, 
									char *resultBuf,
									SchemaErrorNo *errorNo,
									... /* variable number of argument data pointers */) 
{
	ParamVals params;
	va_list ap;
	short i;
	params.numParams = commandDesc->params.numParams;
	va_start(ap, errorNo);
	for (i = 0; i < params.numParams; i++)
		params.paramDataPtr[i] = va_arg(ap, char*);
	va_end(ap);
	return TOS_COMMAND(SCHEMA_INVOKE_COMMAND_WITH_PARAMS)(commandDesc, 
				resultBuf, errorNo, &params);
}

char TOS_COMMAND(SCHEMA_INVOKE_COMMAND_WITH_PARAMS)(CommandDescPtr commandDesc, 
									char *resultBuf,
									SchemaErrorNo *errorNo,
									ParamVals *params)
{
	CommandCallInfo *callInfo = allocCommandCallInfo();
	if (commandDesc == NULL || callInfo == NULL)
		return TOS_Failure;
	callInfo->commandDesc = commandDesc;
	callInfo->resultBuf = resultBuf;
	callInfo->cleanupFunc = freeCommandCallInfo;
	callFunction(commandDesc->commandFunc, params, callInfo);
	*errorNo = callInfo->errorNo;
	if (*errorNo != SCHEMA_RESULT_PENDING)
		// free CommandCallInfo if not split-phase
		freeCommandCallInfo(callInfo);
	if (*errorNo == SCHEMA_ERROR)
		return TOS_Failure;
	return TOS_Success;
}

/* Add a new command to the schema with the specified parameters and procedure pointer */
char TOS_COMMAND(SCHEMA_ADD_COMMAND)(char *commandName, 
								func_ptr commandFunc, 
								TOSType retType,
								int1 retLen,
								int1 nargs, 
								... /* variable number of TOSType's */)
{
	short cmdIdx;
	va_list ap;
	bool cmdExists = FALSE;
	short i;
	CommandDesc *cmd;
	if (nargs > MAX_PARAMS)
		return TOS_Failure;
	if (VAR(addCmdPending) || strlen(commandName) > MAX_CMD_NAME_LEN)
		return TOS_Failure;
	else
		VAR(addCmdPending) = TRUE;
	// replace command definition if one with same name exists
	for (cmdIdx = 0; cmdIdx < VAR(commandDescs).numCmds; cmdIdx++)
		if (strcmp(VAR(commandDescs).commandDesc[cmdIdx].name, commandName) == 0)
		{
			cmdExists = TRUE;
			break;
		}
	if (!cmdExists)
	{
		if (VAR(commandDescs).numCmds < MAX_COMMANDS)
			VAR(commandDescs).numCmds++;
		else
		{
			VAR(addCmdPending) = FALSE;
			return TOS_Failure;
		}
	}
	cmd = &VAR(commandDescs).commandDesc[cmdIdx];
	cmd->idx = cmdIdx;
	strcpy(cmd->name, commandName);
	cmd->commandFunc = commandFunc;
	cmd->retType = retType;
	cmd->retLen = SIZEOF(retType);
	if (cmd->retLen < 0)
		cmd->retLen = retLen; // only use retLen for variable-length types
	cmd->params.numParams = nargs;
	va_start(ap, nargs);
	for (i = 0; i < nargs; i++)
		cmd->params.params[i] = va_arg(ap, TOSType);
	va_end(ap);
	VAR(addCmdPending) = FALSE;
	return TOS_Success;
}

TOS_MsgPtr TOS_EVENT(INVOKE_COMMAND_MSG)(TOS_MsgPtr msg)
{
	char *commandName;
	CommandDesc *cmd;
	char *ptr;
	short nodeid;
	bool splitPhase = FALSE;
	// XXX can only invoke one command at a time
	if (VAR(commandMsgPending))
		return msg;
	VAR(commandMsgPending) = TRUE;
	VAR(msg) = *msg;
	ptr = &VAR(msg).data[0];
	nodeid = *(short*)ptr;
	if (nodeid == TOS_BCAST_ADDR || nodeid == TOS_LOCAL_ADDRESS)
	{
		ptr += sizeof(short);
		commandName = ptr;
		cmd = TOS_COMMAND(SCHEMA_GET_COMMAND)(commandName);
		if (cmd != NULL)
		{
			short i;
			ParamVals paramVals;
			SchemaErrorNo errorNo;
			char resultBuf[16];
			for (i = 0, ptr += strlen(commandName) + 1; i < cmd->params.numParams; i++)
			{
				paramVals.paramDataPtr[i] = ptr;
				ptr += LENGTH(cmd->params.params[i], ptr);
			}
			paramVals.numParams = cmd->params.numParams;
			TOS_COMMAND(SCHEMA_INVOKE_COMMAND_WITH_PARAMS)(cmd, resultBuf, &errorNo, &paramVals);
			if (errorNo == SCHEMA_RESULT_PENDING && cmd->retType != VOID)
				splitPhase = TRUE;
			else if (cmd->retType != VOID)
			{
					// XXX add code later to send return value
#if 0
					char *ptr = &Var(msg).data[0] + strlen(commandName) + 1;
					if (errorNo == SCHEMA_RESULT_NULL)
						*ptr = 1;  // set null indicator
					else
						*ptr = 0;
					memcpy(ptr + 1, resultBuf, cmd->retLen);
					TOS_CALL_COMMAND(SCHEMA_SUB_SEND_MSG)(TOS_BCAST_ADDR, 
							AM_MSG(COMMAND_RETURN_MSG), &msg);
#endif
			}
		}
	}
	if (!splitPhase)
		VAR(commandMsgPending) = FALSE;
	return msg;
}

// XXX deal with split-phase commands later
#if 0
void TOS_EVENT(COMMAND_COMPLETE)(CommandDescPtr commandDesc, char *resultBuf, SchemaErrorNo errorNo)
{
	VAR(commandMsgPending) = FALSE;
	// XXX add code later to send return value
}
#endif
