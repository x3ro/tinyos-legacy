// $Id: TASKResult.java,v 1.2 2003/10/07 21:46:06 idgay Exp $

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

import java.util.*;
import java.io.*;
import java.sql.Timestamp;

/**
 * Class encapsulating TASK query results
 */
public class TASKResult implements Serializable
{
	public TASKResult(int queryId, Vector fieldValues, Vector fieldInfos)
	{
		this.queryId = queryId;
		this.values = fieldValues;
		this.fieldInfos = fieldInfos;
	}

	/**
	 * Returns value of i-th field.  i is 0-based.
	 *
	 * @return	Java object of the field value to be cast to the proper type,
	 *			null if i is invalid.
	 */
	public Object getField(int i) { return values.elementAt(i); };
	/**
	 * Returns value of the field with the specified name
	 *
	 * @return Java object for the field value to be cast to the proper type,
	 *			null if name if invalid.
	 */
	public Object getField(String name) 
	{
		for (int i = 0; i < values.size(); i++)
		{
			if (((TASKFieldInfo)fieldInfos.elementAt(i)).name.equalsIgnoreCase(name))
				return values.elementAt(i);
		}
		return null;
	};
	/**
	 * Returns field information for i-th field. i is 0-based.
	 * null is returned if i is invalid.
	 */
	public TASKFieldInfo getFieldInfo(int i) 
	{ 
		return (TASKFieldInfo)fieldInfos.elementAt(i); 
	};
	/**
	 * Returns field information for named field, null if name is invalid.
	 */
	public TASKFieldInfo getFieldInfo(String name) 
	{
		for (int i = 0; i < fieldInfos.size(); i++)
		{
			if (((TASKFieldInfo)(fieldInfos.elementAt(i))).name.equalsIgnoreCase(name))
				return (TASKFieldInfo)fieldInfos.elementAt(i);
		}
		return null;
	};
	/**
	 * Returns number of fields in the result
	 */
	public int getNumFields() { return fieldInfos.size(); };
	/**
	 * Returns the query id of the query that generated this result
	 */
	public int getQueryId() { return queryId; };
	/**
	 * Returns the epoch number of the result.  Epoch number is always a
	 * field in any TASKResult.  This is just a short-hand for
	 * ((Integer)getField("epoch")).intValue() {};
	 * 
	 */
	public int getEpochNo() { return ((Integer)getField("epoch")).intValue(); };
	/**
	 * Returns the logical time stamped by the mote that produced the
	 * result.  This is also always a field in any TASKResult.  This
	 * method is just short-hand for (Timestamp)getField("motetime").
	 */
	public Timestamp getMoteTime() { return (Timestamp)getField("motetime"); };

	private int queryId;		// id of query that generated the result
	private Vector values;		// Vector of Object's for field values
	private Vector fieldInfos;	// Vector of TASKFieldInfo's
};
