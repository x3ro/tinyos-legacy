// $Id: minmax.h,v 1.1 2005/04/21 23:20:45 shawns Exp $

/*                                                                      tab:2
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

/*
 * @author Cory Sharp
 */

#ifndef _H_minmax_h
#define _H_minmax_h


//
// Gosh, I got sick of writing these routines over and over and over.
// So here they are.
//
// min(a,b) = return the min of a and b
// max(a,b) = return the max of a and b
// minmax(a,lb,ub) = returns a bounded by [lb,ub]
//
// in all cases, only operator < is used
// and if < returns false by default (if they're uncomparable), 
// then a is returned in in preference preference b
// 


template <class T> T min( T a, T b ) 
{ 
  return (b < a) ? b : a; 
}


template <class T> T max( T a, T b )
{
  return (a < b) ? b : a;
}


template <class T> T minmax( T a, T lower_bound, T upper_bound )
{
  return (a < lower_bound) ? lower_bound : ((upper_bound < a) ? upper_bound : a);
}


#endif // _H_minmax_h

