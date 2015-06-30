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

//Header fields for Commands -- See CommandUse.ti and CommandRegister.ti

#include <stdarg.h>

enum {
	MAX_PARAMS = 4,
	MAX_COMMANDS = 8,
	MAX_CMD_NAME_LEN = 8
};

// WH: got rid of byRef.  let's make all types by reference.  NULL pointer means NULL value.

// XXX only handles C functions for now, 

typedef struct {
	uint8_t numParams;	
	TOSType params[MAX_PARAMS];  //length == numParams
} ParamList;

struct CommandMsg {
    short nodeid;
    char fromBase;
    char data[0];  
};

enum {
  AM_COMMANDMSG = 103
};

typedef struct {
	uint8_t idx; // index into CommandDesc array
	char name[MAX_CMD_NAME_LEN + 1];
	uint8_t id; // id for CommandRegister interface dispatch
	TOSType retType;
	uint8_t retLen;
	ParamList params;
} CommandDesc;

typedef CommandDesc *CommandDescPtr;

typedef struct {
	uint8_t numCmds;
	CommandDesc commandDesc[MAX_COMMANDS];
} CommandDescs;

typedef CommandDescs *CommandDescsPtr;

typedef struct {
  uint8_t numParams;	
  char *paramDataPtr[MAX_PARAMS];  //list of pointers of parameter data, 
  			  // NULL pointer means NULL value
} ParamVals;

void
setParamList(ParamList *params, uint8_t nargs, ... /* variable number of TOSType arguments */)
{
	short i;
	va_list ap;
	params->numParams = nargs;
	va_start(ap, nargs);
	for (i = 0; i < nargs; i++)
		params->params[i] = va_arg(ap, TOSType);
	va_end(ap);
}
