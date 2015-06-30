/*									tab:2
 *
 *
 * "Copyright (c) 2000 and The Regents of the University 
 * of California.  All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice and the following
 * two paragraphs appear in all copies of this software.
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
 * Authors:		Phil Levis
 * Use:                 Converts TOSSIM time values to real world time.
 *                      (long to h:m:s)
 */

package net.tinyos.tossim;


public class TimeConverter {

    public static String convert(long time) {
	String timeStr = "";

	long seconds = time / (long)4000000;
	long minutes = seconds / (long)60;
	long hours = minutes / (long)60;
	long bSeconds = time % (long) 4000000;
	
	bSeconds *= 250;
	seconds %= 60;
	minutes %= 60;
	
	timeStr += hours + ":" + minutes + ":" + seconds;
	String bString = "" + bSeconds;
	while(bString.length() < 9) {
	    bString = "0" + bString;
	}
	
	timeStr += "." + bString;
	return timeStr;
    }
}
