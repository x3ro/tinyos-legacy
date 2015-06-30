//$Id: C55xxTimer.h,v 1.1 2005/07/29 18:29:30 adchristian Exp $

/* "Copyright (c) 2000-2003 The Regents of the University of California.  
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement
 * is hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY
 * OF CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 */

//@author Cory Sharp <cssharp@eecs.berkeley.edu>

#ifndef _H_C55xxTimer_h
#define _H_C55xxTimer_h

typedef struct 
{
  int ccifg : 1;    // capture/compare interrupt flag
  int cov : 1;      // capture overflow flag
  int out : 1;      // output value
  int cci : 1;      // capture/compare input value
  int ccie : 1;     // capture/compare interrupt enable
  int outmod : 3;   // output mode
  int cap : 1;      // 1=capture mode, 0=compare mode
  int clld : 2;     // compare latch load
  int scs : 1;      // synchronize capture source
  int ccis : 2;     // capture/compare input select: 0=CCIxA, 1=CCIxB, 2=GND, 3=VCC
  int cm : 2;       // capture mode: 0=none, 1=rising, 2=falling, 3=both
} C55xxCompareControl_t;

#endif//_H_C55xxTimer_h

