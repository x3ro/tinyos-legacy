// $Id: TASKTypes.java,v 1.2 2003/10/07 21:46:06 idgay Exp $

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
package net.tinyos.task.taskapi;

import net.tinyos.tinydb.QueryField;

/**
 * Class defining constants for TASK type Ids
 */
public class TASKTypes
{
	public static final String TypeName[] = {"int8", "uint8", "int16", "uint16", "int32", "timestamp32", "timestamp64", "string", "bool", "void", "bytes"};
	public static final int INVALID_TYPE	= -1;	// invalid type id
	public static final int INT8			= 0;	// signed 8-bit integer
	public static final int UINT8			= 1;	// unsigned 8-bit integer
	public static final int INT16			= 2;	// signed 16-bit integer
	public static final int UINT16			= 3;	// unsigned 16-bit integer
	public static final int INT32			= 4;	// signed 32-bit integer
	public static final int TIMESTAMP32		= 5;	// 32-bit timestamp
	public static final int TIMESTAMP64		= 6;	// 64-bit timestamp
	public static final int STRING			= 7;	// null-terminated string
	public static final int BOOL			= 8;	// boolean type
	public static final int VOID			= 10;	// void type
	public static final int BYTES			= 9;	// void type

	public static int typeLen(int type)
	{
		switch (type)
		{
			case INT8:
			case UINT8:
				return 1;
			case INT16:
			case UINT16:
				return 2;
			case INT32:
			case TIMESTAMP32:
				return 4;
			case TIMESTAMP64:
				return 8;
			case BOOL:
				return 1;
			case VOID:
				return 0;
			case STRING:
				return 9; // XXX fixed size 8 character strings for now
			case BYTES:
				return 8; // XXX fixed size 8-byte byte string for now
		}
		return -1;
	};

	public static int tinyDBTypeToTASKType(byte type)
	{
		switch (type)
		{
			case QueryField.INTONE:
				return INT8;
			case QueryField.UINTONE:
				return UINT8;
			case QueryField.INTTWO:
				return INT16;
			case QueryField.UINTTWO:
				return UINT16;
			case QueryField.INTFOUR:
				return INT32;
			case QueryField.STRING:
				return STRING;
			case QueryField.TIMESTAMP:
				return TIMESTAMP32;
			case QueryField.BYTES:
				return BYTES;
		}
		return INVALID_TYPE;
	}
};
