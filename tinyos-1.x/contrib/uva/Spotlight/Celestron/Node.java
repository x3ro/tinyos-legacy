//$Header: /cvsroot/tinyos/tinyos-1.x/contrib/uva/Spotlight/Celestron/Node.java,v 1.1.1.1 2005/05/10 23:37:06 rsto99 Exp $

/* "Copyright (c) 2000-2004 University of Virginia.  
 * All rights reserved.
 * 
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF VIRGINIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY OF
 * VIRGINIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF VIRGINIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF VIRGINIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 */

// Author: Radu Stoleru
// Date: 3/26/2005

public class Node {
	int id;
	int altRawValue;
	int azRawValue;
		
	public int altDeg() {
		double arcsecs = (double) (altRawValue*1296000.0/65536.0);
		return (int) Math.floor(arcsecs/3600.0);
	}
	
	public int altMin() {
		double arcsecs = (double) (altRawValue*1296000.0/65536.0);
		int deg = (int) Math.floor(arcsecs/3600.0);
		return (int) Math.floor((arcsecs - deg*3600.0)/60.0);
	}
	
	public double altSec() {
		double arcsecs = (double) (altRawValue*1296000.0/65536.0);
		int deg = (int) Math.floor(arcsecs/3600.0);
		int min = (int) Math.floor((arcsecs - deg*3600.0)/60.0);
		return (arcsecs - deg*3600 - min*60);
	}

	public int azDeg() {
		double arcsecs = (double) (azRawValue*1296000.0/65536.0);
		return (int) Math.floor(arcsecs/3600.0);
	}
	
	public int azMin() {
		double arcsecs = (double) (azRawValue*1296000.0/65536.0);
		int deg = (int) Math.floor(arcsecs/3600.0);
		return (int) Math.floor((arcsecs - deg*3600.0)/60.0);
	}
	
	public double azSec() {
		double arcsecs = (double) (azRawValue*1296000.0/65536.0);
		int deg = (int) Math.floor(arcsecs/3600.0);
		int min = (int) Math.floor((arcsecs - deg*3600.0)/60.0);
		return (arcsecs - deg*3600 - min*60);
	}
	
}
