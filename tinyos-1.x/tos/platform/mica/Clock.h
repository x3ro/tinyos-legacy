// $Id: Clock.h,v 1.2 2003/10/07 21:46:29 idgay Exp $

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
// Usage is Clock.setRate(TOS_InPS, TOS_SnPS)
enum {
  TOS_I1000PS = 33,  TOS_S1000PS = 1,
  TOS_I100PS  = 41,  TOS_S100PS  = 2,
  TOS_I10PS   = 102, TOS_S10PS   = 3,
  TOS_I4096PS = 1,   TOS_S4096PS = 2,
  TOS_I2048PS = 2,   TOS_S2048PS = 2,
  TOS_I1024PS = 1,   TOS_S1024PS = 3,
  TOS_I512PS  = 2,   TOS_S512PS  = 3,
  TOS_I256PS  = 4,   TOS_S256PS  = 3,
  TOS_I128PS  = 8,   TOS_S128PS  = 3,
  TOS_I64PS   = 16,  TOS_S64PS   = 3,
  TOS_I32PS   = 32,  TOS_S32PS   = 3,
  TOS_I16PS   = 64,  TOS_S16PS   = 3,
  TOS_I8PS    = 128, TOS_S8PS    = 3,
  TOS_I4PS    = 128, TOS_S4PS    = 4,
  TOS_I2PS    = 128, TOS_S2PS    = 5,
  TOS_I1PS    = 128, TOS_S1PS    = 6,
  TOS_I0PS    = 0,   TOS_S0PS    = 0
};
enum {
  DEFAULT_SCALE=3, DEFAULT_INTERVAL=128
};

