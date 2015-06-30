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
 * Date:     7/1/2002
 *
 */

#ifndef __SCHEMATYPE_H__
#define __SCHEMATYPE_H__

typedef enum {
	SCHEMA_SUCCESS = 0,
	SCHEMA_ERROR,
	SCHEMA_RESULT_READY,
	SCHEMA_RESULT_NULL,
	SCHEMA_RESULT_PENDING
} SchemaErrorNo;

typedef enum {
	VOID = 0,
	INT8 = 1,
	UINT8 = 2,
	INT16 = 3,
	UINT16 = 4,
	INT32 = 5,
	UINT32 = 6,
	TIMESTAMP =7,
	STRING = 8,
	COMPLEX_TYPE =9 //e.g. a list, tree, etc.
} TOSType;

short
sizeOf(TOSType type)
{
	switch (type) {
	case VOID:
		return 0;
	case INT8:
	case UINT8:
		return 1;
	case INT16:
	case UINT16:
		return 2;
	case INT32:
	case UINT32:
		return 4;
	case TIMESTAMP:
		return 4;
	case STRING:
	  return 8; //hack! strings are of size 8...
	default:
	  break;
	}
	return -1;
}

short
lengthOf(TOSType type, char *data)
{
	short len = sizeOf(type);
	if (type == STRING)
		len = strlen(data) + 1;
	return len;
}

struct CommandMsg {
    short nodeid;
    char fromBase;
    char data[0];  
};

#endif /* __SCHEMATYPE_H__ */
