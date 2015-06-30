/*
 * Copyright (c) 2003, Vanderbilt University
 * All rights reserved.
 *
 * Permission to use, copy,	modify,	and	distribute this	software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided	that the above copyright notice, the following
 * two paragraphs and the author appear	in all copies of this software.
 *
 * IN NO EVENT SHALL THE VANDERBILT	UNIVERSITY BE LIABLE TO	ANY	PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE VANDERBILT
 * UNIVERSITY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * THE VANDERBILT UNIVERSITY SPECIFICALLY DISCLAIMS	ANY	WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF	MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR	PURPOSE.  THE SOFTWARE PROVIDED	HEREUNDER IS
 * ON AN "AS IS" BASIS,	AND	THE	VANDERBILT UNIVERSITY HAS NO OBLIGATION	TO
 * PROVIDE MAINTENANCE,	SUPPORT, UPDATES, ENHANCEMENTS,	OR MODIFICATIONS.
 */
/*									tab:4
 *  CircularBuffer.java - This class is especcially good for counting moving average.
 *	
 *  Author:  Gabor Pap
 *  Date:     03/21/2002
 */
package isis.nest.util;

import java.util.*;

public class CircularBuffer {
	private ArrayList list;
	private int lastItemInserted;
	private int bufferSize;
	private boolean firstRun = true;
	
	/** Creates a new instance of CircularBuffer defining the size */
	public CircularBuffer(int size) {
		list = new ArrayList(size);
		lastItemInserted = 0;
		bufferSize = size;
	}
	
	/** Inserts an object to the buffer and returns the replaced one, returns null while filling up*/
	public Object insert(Object o){
		Object toBeReturned;
		if (firstRun){
			list.add(o);
			toBeReturned = null;
		}else{
			toBeReturned = list.set(lastItemInserted, o);
		}
		lastItemInserted++;
		if (lastItemInserted == bufferSize){
			lastItemInserted = 0;
			if (firstRun){
				firstRun = false;
			}
		}
		return toBeReturned;
	}
}
