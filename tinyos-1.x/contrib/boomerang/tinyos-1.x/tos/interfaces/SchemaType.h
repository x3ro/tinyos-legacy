// $Id: SchemaType.h,v 1.1.1.1 2007/11/05 19:09:03 jpolastre Exp $

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
 * Date:     7/1/2002
 *
 */

/**
 * @author Wei Hong
 * @author Intel Research Berkeley Lab
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
	BYTES = 9,
	COMPLEX_TYPE =10 //e.g. a list, tree, etc.
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
	case BYTES:
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
  uint32_t seqNo;
  char data[0];  
};

#endif /* __SCHEMATYPE_H__ */
