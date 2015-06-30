// $Id: TASKFieldInfo.java,v 1.2 2003/10/07 21:46:06 idgay Exp $

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

import java.io.*;
import net.tinyos.tinydb.*;

/**
 * Information about a field in a query.  A field can be an attribute
 * or the result of an expression
 */
public class TASKFieldInfo implements Serializable
{
	/**
	 * Constructor for TASKFieldInfo.
	 *
	 * @param	name	name of the field.
	 * @param	type	type id of the field.
	 */
	public TASKFieldInfo(String name, int type) 
	{
		this.name = name;
		this.type = type;
	};

	public TASKFieldInfo(QueryField qf)
	{
		this(qf.getName(), TASKTypes.INVALID_TYPE);
		int type = TASKTypes.INVALID_TYPE;
		switch (qf.getType())
		{
			case QueryField.INTONE:
				type = TASKTypes.INT8;
				break;
			case QueryField.UINTONE:
				type = TASKTypes.UINT8;
				break;
			case QueryField.INTTWO:
				type = TASKTypes.INT16;
				break;
			case QueryField.UINTTWO:
				type = TASKTypes.UINT16;
				break;
			case QueryField.INTFOUR:
				type = TASKTypes.INT32;
				break;
			case QueryField.TIMESTAMP:
				type = TASKTypes.TIMESTAMP32;
				break;
			case QueryField.STRING:
				type = TASKTypes.STRING;
				break;
			case QueryField.BYTES:
				type = TASKTypes.BYTES;
				break;
		}
		this.type = type;
	}

	public String	name;	// field name
	public int		type;	// field type as defined in TASKTypes
};
