// $Id: TASKAggExpr.java,v 1.2 2003/10/07 21:46:05 idgay Exp $

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

/**
 * Class for aggregate expressions.  For now, TASK only supports
 * temporal aggregates with one attribute argument and up to two constant
 * arguments: typically one for window size and sliding distance.
 */
public class TASKAggExpr extends TASKExpr implements Serializable
{
	/**
	 * Constructor for TASKAggExpr.
	 *
	 * @param	name	name of aggregate.
	 * @param	attrName	name of attribute argument.
	 * @param	const1	value of first constant argument, null if irrelevant.
	 * @param	const2	value of second constant argument, null if irrelevant.
	 */
	public TASKAggExpr(String name, String attrName, Integer const1, Integer const2) 
	{
		this.name = name;
		this.attrName = attrName;
		this.const1 = const1;
		this.const2 = const2;
	};
	/**
	 * Returns name of the aggregate.
	 */
	public String getName() 
	{
		return name;
	};
	/**
	 * Returns name of the attribute argument.
	 */
	public String getAttrName() 
	{
		return attrName;
	};
	/**
	 * Returns value of the first constant, which is typically a window size
	 * in terms of number of epochs.
	 */
	public Integer getConst1() 
	{
		return const1;
	};
	/**
	 * Returns value of the second constant, which is typically a sliding
	 * distance in terms of number of epochs.
	 */
	public Integer getConst2() 
	{
		return const2;
	};

	public String toString()
	{
		String str = name + "(";
		if (const1 != null)
		{
			str += const1;
			str += ",";
		}
		if (const2 != null)
		{
			str += const2;
			str += ",";
		}
		str += attrName;
		str += ")";
		return str;
	}

	private String	name;			// name of aggregate
	private String	attrName;		// name of attribute
	private Integer	const1;			// value of first constant
	private Integer	const2;			// value of second constant
};
