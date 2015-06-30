// $Id: TASKOperators.java,v 1.2 2003/10/07 21:46:06 idgay Exp $

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

import net.tinyos.tinydb.SelOp;

/**
 * Class defining constants for TASK operator types
 */
public class TASKOperators
{
	public static final String OperName[] = {"=", ">", ">=", "<", "<=", "<>", "+", "-", "*", "/", "<<", ">>"};
	public static final int INVALID_OPER	= -1; // invalid operator
	public static final int EQ			= 0;	// equal operator.
	public static final int GT			= 1;	// greater than operator.
	public static final int GE			= 2;	// greater than or equal to.
	public static final int LT			= 3;	// less than operator.
	public static final int LE			= 4;	// less than or equal to.
	public static final int NE			= 5;	// not equal
	public static final int PLUS		= 6;	// addition
	public static final int MINUS		= 7;	// subtraction
	public static final int TIMES		= 8;	// multiplication
	public static final int DIV			= 9;	// division
	public static final int LSHIFT		= 10;	// left bit shift
	public static final int RSHIFT		= 11;	// right bit shift

	public static int opTypeFromSelOp(byte selOp)
	{
		switch (selOp)
		{
			case SelOp.OP_EQ:
				return EQ;
			case SelOp.OP_NEQ:
				return NE;
			case SelOp.OP_GT:
				return GT;
			case SelOp.OP_GE:
				return GE;
			case SelOp.OP_LT:
				return LT;
			case SelOp.OP_LE:
				return LE;
		}
		return INVALID_OPER;
	}
};
