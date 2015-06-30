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
 * Authors:  Wei Hong, Sam Madden
 *           Intel Research Berkeley Lab
 * Date:     5/01/2002
 *
 */

/* The purpose of the mote schema is to track attributes (e.g. sensor, light, power, neighbors) and commands
(e.g. set the red led, get the temperature.)  The Schema API providse a simple interface for components to 
register the attributes and commands they provide, and for external users to query those attributes and
commands. */

// And the supporting data structures:

#ifndef __SCHEMAAPI__
#define __SCHEMAAPI__

#include "SchemaError.h"
#include "util.h"

#define MAX_PARAMS	4
#define MAX_ATTRS	9
// each ATTR can potentially generate 2 commands
#define MAX_COMMANDS	2 * MAX_ATTRS + 4
#define MAX_CONST_SIZE	4
#define MAX_ATTR_NAME_LEN	8	// WH: can we get away with this??
// we auto-generate get/set commands for each attribute by prepending "get"
// or "set" to attribute names
#define MAX_CMD_NAME_LEN	MAX_ATTR_NAME_LEN + 3
#define MAX_CONCURRENT_COMMANDS		MAX_COMMANDS


typedef enum {
	VOID = 0,
	INTONE,
	INTTWO,
	INTFOUR,
	STRING,
	TIMESTAMP,
	COMPLEX_TYPE //e.g. a list, tree, etc.
} TOSType;

#define SIZEOF(X)	((X) == VOID ? 0 : ((X) == INTONE ? 1 : ((X) == INTTWO ? 2 : ((X) == INTFOUR ? 4 : ((X) == TIMESTAMP ? 4 : -1)))))
#define LENGTH(X, DATA)	((X) == VOID ? 0 : ((X) == INTONE ? 1 : ((X) == INTTWO ? 2 : ((X) == INTFOUR ? 4 : ((X) == TIMESTAMP ? 4 : ((X) == STRING ? strlen(DATA) + 1 : -1))))))

// WH: got rid of byRef.  let's make all types by reference.  NULL pointer means NULL value.

// XXX only handles C functions for now, 

typedef struct {
	int1 numParams;	
	TOSType params[MAX_PARAMS];  //length == numParams
} ParamList;

typedef struct {
	int1 idx;
	char name[MAX_CMD_NAME_LEN + 1];
	func_ptr commandFunc;
	TOSType retType;
	int1 retLen;
	ParamList params;
} CommandDesc;

typedef CommandDesc *CommandDescPtr;

typedef struct {
	int1 numCmds;
	CommandDesc commandDesc[MAX_COMMANDS];
} CommandDescs;

typedef CommandDescs *CommandDescsPtr;

// WH: should we call this Unit or Type (like in Mate, one per sensor type)?
typedef enum {
	UNKNOWN_UNIT = 0,
	CELCIUS,
	FARENHEIGHT,
	LUMENS,
	//lots more, i'm sure
	COMPLEX_UNIT //e.g. a list of neighbors
} Unit;

// will add support for other languages later
typedef struct {
	TOSType type;	
    char idx; //need this, if we get attr by name but want to ref by idx
	int1 nbytes;
	func_ptr getFunction; // WH: what happened to split-phase?
	func_ptr setFunction; // WH: command to assign a value to the attr
	char getCommand; // auto-generated command for getting attr value
	char setCommand; // auto-generated command for setting attr value
	char name[MAX_ATTR_NAME_LEN + 1];
	/*
	// the following are not used for now
	Unit units;
	char calibrationTable;  //reference to CALIBRATION component
			       //maps raw ADC values into units	
	int1 sampleCost;
	int1 sampleTime;
	int2 min;
	int2 max;
	bool isConst; // true if the attr returns a constant value
	*/
} AttrDesc;

typedef AttrDesc *AttrDescPtr;

typedef struct {
  int1 numAttrs;
  AttrDesc attrDesc[MAX_ATTRS];
} AttrDescs;

typedef AttrDescs *AttrDescsPtr;

typedef struct {
  int1 numParams;	
  char *paramDataPtr[MAX_PARAMS];  //list of pointers of parameter data, 
  			  // NULL pointer means NULL value
} ParamVals;

typedef struct {
    CommandDescPtr commandDesc;
    char *resultBuf;
	SchemaErrorNo errorNo;
	func_ptr cleanupFunc;
} CommandCallInfo;

#define SCHEMA_END_COMMAND(COMMAND_COMPLETE_EVENT, callInfo) \
			{ \
				CommandCallInfo *ci = (callInfo); \
				CommandDescPtr command = ci->commandDesc; \
				char *resultBuf = ci->resultBuf; \
				SchemaErrorNo errorNo = ci->errorNo; \
				ci->cleanupFunc(ci); \
				TOS_SIGNAL_EVENT(COMMAND_COMPLETE_EVENT)(command, resultBuf, errorNo); \
			}
#endif
