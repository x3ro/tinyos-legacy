// $Id: TASKAggInfo.java,v 1.2 2003/10/07 21:46:05 idgay Exp $

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

import net.tinyos.tinydb.AggOp;



/**

 * Aggregate Information.

 */

public class TASKAggInfo implements Serializable

{

	/**

	 * Constructor for TASKAggInfo.

	 *

	 * @param	name	aggregate name.

	 * @param	argType	the type of the non-constant argument.

	 * @param	numConstArgs	number of constant arguments: 0, 1 or 2.

	 * @param	retType	the return type.

	 * @param	description	a brief description

	 */

	public TASKAggInfo(String name, int argType, int numConstArgs, int retType, String description)

	{

		this.name = name;

		this.argType = argType;

		this.numConstArgs = numConstArgs;

		this.retType = retType;

		this.description = description;

	};

	/**

	 * Returns name of aggregate.

	 */

	public String getName() {  return name; };

	/**

	 * Returns argument type as defined in TASKTypes.

	 */

	public int getArgType() { return argType; };

	/**

	 * Return number of constant arguments: 0, 1, or 2.

	 */

	public int getNumConstArgs() {  return numConstArgs; };

	/**

	 * Return the aggregate return type as defined in TASKTypes.

	 */

	public int getRetType() {  return retType; };

	/**

	 * Return the aggregate description.

	 */

	public String getDescription() {  return description; };



	/**

	 * returns TASK aggregate name from a TinyDB aggregate opcode.

	 * @param opCode TinyDB opcode defined in AggOp

	 * @return TASK aggregate name

	 */

	public static String aggNameFromOpCode(byte opCode)

	{

		switch (opCode)

		{

			case 7:

				return "winavg";

			case 8:

				return "winsum";

			case 9:

				return "winmin";

			case 10:

				return "winmax";

			case 11:

				return "wincnt";

			case 6:

				return "expavg";

		}

		return null;

	}



	private String	name;			// name of aggregate

	private int		argType;		// argument type

	private int		numConstArgs;	// number of constant arguments

	private int		retType;		// return type of aggregate

	private String description;		// a brief description

};

