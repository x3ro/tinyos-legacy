// $Id: TASKOperExpr.java,v 1.2 2003/10/07 21:46:06 idgay Exp $

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
 * Class for operator expressions.
 */
public class TASKOperExpr extends TASKExpr implements Serializable
{
	/**
	 * Constructor for TASKOperExpr.
	 *
	 * @param	operType	operator type defined in TASKOperators.
	 * @param	leftExpr	left expression.
	 * @param	rightExpr	right expression.
	 */
	public TASKOperExpr(int opType, TASKExpr lexpr, TASKExpr rexpr) 
	{
		operType = opType;
		leftExpr = lexpr;
		rightExpr = rexpr;
		exprRetType = operType();
	};
	/**
	 * Returns operator type as defined in TASKOperators
	 */
	public int getOperType() {  return operType; };
	/**
	 * Returns the left expression of the operator
	 */
	public TASKExpr getLeftExpr() {  return leftExpr; };
	/**
	 * Returns the right expression of the operator
	 */
	public TASKExpr getRightExpr() {  return rightExpr;  };

	private int operType()
	{
		switch (operType)
		{
			case TASKOperators.EQ:
			case TASKOperators.GT:
			case TASKOperators.GE:
			case TASKOperators.LT:
			case TASKOperators.LE:
			case TASKOperators.NE:
				return TASKTypes.BOOL;
			case TASKOperators.PLUS:
			case TASKOperators.MINUS:
			case TASKOperators.TIMES:
			case TASKOperators.DIV:
			case TASKOperators.LSHIFT:
			case TASKOperators.RSHIFT:
				// return the larger numeric type
				if (TASKTypes.typeLen(leftExpr.getExprRetType()) < 
						TASKTypes.typeLen(rightExpr.getExprRetType()))
					return rightExpr.getExprRetType();
				return leftExpr.getExprRetType();
		}
		return TASKTypes.INVALID_TYPE;
	};

	public String toString()
	{
		String str = leftExpr.toString();
		str += " " + TASKOperators.OperName[operType] + " ";
		str += rightExpr.toString();
		return str;
	}

	private int		operType;	// operate type as defined in TASKOperators
	private TASKExpr	leftExpr;	// left expression
	private TASKExpr	rightExpr;	// right expression
};
