/*									tab:4
 *  IMPORTANT: READ BEFORE DOWNLOADING, COPYING, INSTALLING OR USING.  By
 *  downloading, copying, installing or using the software you agree to
 *  this license.  If you do not agree to this license, do not download,
 *  install, copy or use the software.
 *
 *  Intel Open Source License 
 *
 *  Copyright (c) 2002 Intel Corporation 
 *  All rights reserved. 
 *  Redistribution and use in source and binary forms, with or without
 *  modification, are permitted provided that the following conditions are
 *  met:
 * 
 *	Redistributions of source code must retain the above copyright
 *  notice, this list of conditions and the following disclaimer.
 *	Redistributions in binary form must reproduce the above copyright
 *  notice, this list of conditions and the following disclaimer in the
 *  documentation and/or other materials provided with the distribution.
 *      Neither the name of the Intel Corporation nor the names of its
 *  contributors may be used to endorse or promote products derived from
 *  this software without specific prior written permission.
 *  
 *  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 *  ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 *  LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
 *  PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE INTEL OR ITS
 *  CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 *  EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 *  PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 *  PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 *  LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 *  NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 *  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * 
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
