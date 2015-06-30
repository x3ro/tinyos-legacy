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

#include "tos.h"
#include "RANDOM_LFSR.h"

extern short TOS_LOCAL_ADDRESS;

#define TOS_FRAME_TYPE lfsr_frame
TOS_FRAME_BEGIN(lfsr_frame) {
  unsigned int shift_reg;
  unsigned int init_seed;
  unsigned int mask;
}
TOS_FRAME_END(lfsr_frame);



char TOS_COMMAND(LFSR_INIT)(){  
  VAR(shift_reg) = 119 * 119 * TOS_LOCAL_ADDRESS;
  VAR(init_seed) = VAR(shift_reg);
  VAR(mask) = 137*29*TOS_LOCAL_ADDRESS;
  return 1;
}

#if 0
unsigned int TOS_COMMAND(LFSR_NEXT_RAND)(){
  char bit, endbit;

  bit = VAR(shift_reg) & (unsigned int) 0x1;
  if (VAR(shift_reg) & (unsigned int) 0x4000)
    endbit = 1;
  else
    endbit = 0;
  bit ^= endbit;

  VAR(shift_reg) <<=1;

  if (bit & (char) 0x1)
    VAR(shift_reg) |= (unsigned int) 0x2;
  else
    VAR(shift_reg) &= (unsigned int) 0xfffd;

  if (endbit == 1)
    VAR(shift_reg) |= (unsigned int)0x1;
  else
    VAR(shift_reg) &= (unsigned int) 0xfffe;
  
  return ((VAR(shift_reg) & 0x7fff) ^ VAR(mask));
}
#endif

unsigned int TOS_COMMAND(LFSR_NEXT_RAND)(){
  char bit, bit1, bit3, bit12, endbit;
  int tmp_shift_reg = VAR(shift_reg);

  endbit = ((tmp_shift_reg &0x8000) != 0);
  tmp_shift_reg <<= 1;
  if (endbit) {
      tmp_shift_reg ^= 0x100b;
  }

#if 0
  bit1 = VAR(shift_reg) & (unsigned int) 0x1;
  if (VAR(shift_reg) & (unsigned int) 0x4)
    bit3 = 1;
  else
    bit3 = 0;
  if (VAR(shift_reg) & (unsigned int) 0x800)      
    bit12 = 1;
  else
    bit12 = 0;
  if (VAR(shift_reg) & (unsigned int) 0x8000)
    endbit = 1;
  else
    endbit = 0;
  
  VAR(shift_reg) <<=1;
  bit = bit1 ^ endbit;
  if (bit & 0x1)
    VAR(shift_reg) |= (unsigned int) 0x2;
  else
    VAR(shift_reg) &= (unsigned int) 0xfffd;
  
  bit = bit3 ^ endbit;
  if (bit & 0x1)
    VAR(shift_reg) |= (unsigned int) 0x8;
  else
    VAR(shift_reg) &= (unsigned int) 0xfff7;
  
  bit = bit12 ^ endbit;
  if (bit & 0x1)
    VAR(shift_reg) |= (unsigned int) 0x1000;
  else
    VAR(shift_reg) &= (unsigned int) 0xefff;
  
  if (endbit == 1)
    VAR(shift_reg) |= 0x1;
  else
    VAR(shift_reg) &= (unsigned int) 0xfffe;
#endif
  VAR(shift_reg) = tmp_shift_reg;
  
  return VAR(shift_reg) ^ VAR(mask);
}
