/*									tab:4
 *
 *
 * "Copyright (c) 2000-2002 The Regents of the University  of California.  
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
 */
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
/* Authors:   Neil Patel
 * History:   created 6/20/2003
 *            
 */

/**
 * @author Neil Patel
 */


#ifndef BOMBILLA_CONSTANTS_H_INCLUDED
#define BOMBILLA_CONSTANTS_H_INCLUDED

typedef enum {
  BOMB_OPTION_FORWARD     = 0x80,
  BOMB_OPTION_FORCE       = 0x40,
  BOMB_OPTION_MASK = 0x3f,
} BombillaCapsuleOption;

typedef enum {
  BOMB_CAPSULE_SUB0  = 0,
  BOMB_CAPSULE_SUB1  = 1, 
  BOMB_CAPSULE_SUB2  = 2, 
  BOMB_CAPSULE_SUB3  = 3, 
  BOMB_CAPSULE_CLOCK = 4,
  BOMB_CAPSULE_SEND  = 5,
  BOMB_CAPSULE_RECV  = 6,
  BOMB_CAPSULE_ONCE  = 7,
  BOMB_CAPSULE_OUTER = 8,
  BOMB_CONTEXT_NUM   = 4,
  BOMB_CAPSULE_INVALID = 255
} BombillaCapsuleType;

typedef enum {
  OPhalt      = 0x00,
  OPid        = 0x01,
  OPrand      = 0x02,
  OPctrue     = 0x03,
  OPcfalse    = 0x04,
  OPcpush     = 0x05,
  OPlogp      = 0x06,
  OPbpush0    = 0x07,
  OPbpush1    = 0x08,
  OPgetradio  = 0x09,
  OPerr       = 0x0a,
  OPret       = 0x0b,
  OPcall0     = 0x0c,
  OPcall1     = 0x0d,
  OPcall2     = 0x0e,
  OPcall3     = 0x0f,

/* One operand instructions */
  OPinv       = 0x10,
  OPcpull     = 0x11,
  OPnot       = 0x12,
  OPlnot      = 0x13,
  OPsense     = 0x14,
  OPsend      = 0x15,
  OPsendr     = 0x16,
  OPuart      = 0x17,
  OPlogw      = 0x18,
  OPbhead     = 0x19,
  OPbtail     = 0x1a,
  OPbclear    = 0x1b,
  OPbsize     = 0x1c,
  OPcopy      = 0x1d,
  OPpop       = 0x1e,
  OPsetradio  = 0x1f,
  
  OPbsorta    = 0x20,
  OPbsortd    = 0x21,
  OPbfull     = 0x22,
  OPputled    = 0x23,
  OPcast      = 0x24,
  OPunlock    = 0x25,
  OPunlockb   = 0x26,
  OPpunlock   = 0x27,
  OPpunlockb  = 0x28,

/* Two-operand instructions */
  OPlogwl     = 0x2b,
  OPlogr      = 0x2c,
  OPbget      = 0x2d,
  OPbyank     = 0x2e,
/* Special instruction */
  OPmotectl   = 0x2f,

/* Two operand-instructions */
  OPswap      = 0x30,
  OPland      = 0x31,
  OPlor       = 0x32,
  OPand       = 0x33,
  OPor        = 0x34,
  OPshiftr    = 0x35,
  OPshiftl    = 0x36,
  OPadd       = 0x37,
  OPmod       = 0x38,
  OPeq        = 0x39,
  OPneq       = 0x3a,
  OPlt        = 0x3b,
  OPgt        = 0x3c,
  OPlte       = 0x3d,
  OPgte       = 0x3e,
  OPeqtype    = 0x3f,



/*   mclass   */
  OPgetms     = 0x40,
  OPgetmb     = 0x48,
  OPsetms     = 0x50,
  OPsetmb     = 0x58,
  
/*  vclass  */
  OPgetvar    = 0x60,
  OPsetvar    = 0x70,

/*   jclass   */
  OPjumpc     = 0x80,
  OPjumps     = 0xa0,

/*   xclass   */
  OPpushc     = 0xc0
} BombillaInstruction;

#endif
