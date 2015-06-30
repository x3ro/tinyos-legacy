/*                                                                      tab:4
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
 * Authors:             Alec Woo
 *
 *
 */   

/* This is a 16 bit Linear Feedback Shift Register pseudo random number generator */

#include "tos.h"
#include "RANDOM_LFSR.h"
#include "dbg.h"

extern short TOS_LOCAL_ADDRESS;

#define TOS_FRAME_TYPE lfsr_frame
TOS_FRAME_BEGIN(lfsr_frame) {
  unsigned int shift_reg;
  unsigned int init_seed;
  unsigned int mask;
}
TOS_FRAME_END(lfsr_frame);


/* Initialize the seed from the ID of the node */
char TOS_COMMAND(LFSR_INIT)(){
  dbg(DBG_BOOT, ("RANDOM_LFSR initialized.\n"));
  VAR(shift_reg) = 119 * 119 * (TOS_LOCAL_ADDRESS + 1);
  VAR(init_seed) = VAR(shift_reg);
  VAR(mask) = 137*29*(TOS_LOCAL_ADDRESS + 1);
  return 1;
}

/* Return the next 16 bit random number */
short TOS_COMMAND(LFSR_NEXT_RAND)(){
  char endbit;
  int tmp_shift_reg = VAR(shift_reg);

  endbit = ((tmp_shift_reg &0x8000) != 0);
  tmp_shift_reg <<= 1;
  if (endbit) {
      tmp_shift_reg ^= 0x100b;
  }

  VAR(shift_reg) = tmp_shift_reg;
  
  return VAR(shift_reg) ^ VAR(mask);
}
