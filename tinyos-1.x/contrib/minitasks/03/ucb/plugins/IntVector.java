/* "Copyright (c) 2000-2002 The Regents of the University of California.  
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
 */

// Authors: Cory Sharp
// $Id: IntVector.java,v 1.4 2003/07/10 17:56:40 cssharp Exp $

class IntVector
{
  public int v[];

  public int get( int index )
  {
    return (index < v.length) ? v[index] : 0;
  }

  public void set( int index, int value )
  {
    if( index >= 0 )
    {
      if( v.length < index )
      {
	int bigsize = (v.length > 0) ? v.length : 16;
	while( bigsize <= index ) { bigsize *= 2; if( bigsize == 0 ) return; }
	int bigv[] = new int[bigsize];
	for( int i=0; i<v.length; i++ ) { bigv[i] = v[i]; }
	v = bigv;
      }
      v[index] = value;
    }
  }

  public IntVector()
  {
    v = new int[16];
  }
}

