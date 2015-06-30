// $Id: SimpleFP.h,v 1.1.1.1 2007/11/05 19:09:23 jpolastre Exp $

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

#ifndef TOS_SIMPLEFP_H
#define TOS_SIMPLEFP_H

/* A simple fixed-point package, provides unsigned 8.8 precision (easily
   changed) */

enum { FP_BITS = 8 };		/* bits in fraction */
typedef uint16_t FPType;	/* type of fp values */
typedef uint8_t FPIntType;	/* type which can hold integral part of
                                   FPType */
typedef uint32_t FPBigger;

enum { FP_SCALE = 1UL << FP_BITS };

/* + and - can be used directly */
FPType fpMul(FPType fp1, FPType fp2)
{
  return (FPType)(((FPBigger)fp1 * fp2) >> FP_BITS);
}

FPType fpDiv(FPType fp1, FPType fp2)
{
  return (FPType)(((FPBigger)fp1 << FP_BITS) / fp2);
}

FPIntType fpRoundToZero(FPType fp)
{
  return fp >> FP_BITS;
}

FPIntType fpRoundAwayFromZero(FPType fp)
{
  return (fp + (1 << FP_BITS) - 1) >> FP_BITS;
}

FPType intToFp(FPIntType i)
{
  return i << FP_BITS;
}

#endif
