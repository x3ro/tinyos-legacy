/*                                                                      tab:4
 *  IMPORTANT: READ BEFORE DOWNLOADING, COPYING, INSTALLING OR USING.  By
 *  downloading, copying, installing or using the software you agree to
 *  this license.  If you do not agree to this license, do not download,
 *
 */
/*                                                                      tab:4
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
 */
/*                                                                      tab:4
 * Copyright (c) 2003 Intel Corporation
 * All rights reserved Contributions to the above software program by Intel
 * Corporation is program is licensed subject to the BSD License, available at
 * http://www.opensource.org/licenses/bsd-license.html
 *
 */
/*
 * Authors:     Mark Yarvis
 *
 */

// Moved from DSDV.c

// TODO: should include an interface to a source of random noise
module RandomGen {
   provides interface Random;
}

implementation {
   uint32_t last_rand1;
   uint32_t last_rand2;

   enum {
      RANDOM_GEN_RANDSEED1 =   11,
      RANDOM_GEN_RANDSEED2 =   37,
      RANDOM_GEN_RANDMULT  =   16807,
      RANDOM_GEN_RANDCONST =   0,
      RANDOM_GEN_RANDMAX   =   65535U
   };

   async command result_t Random.init() {
      atomic {
         last_rand1 = RANDOM_GEN_RANDSEED1 + 
                          TOS_LOCAL_ADDRESS*TOS_LOCAL_ADDRESS;
         last_rand2 = RANDOM_GEN_RANDSEED2;
      }
      return SUCCESS;
   }

   async command uint16_t Random.rand() {
      uint16_t retval;

      atomic {
         last_rand1 = ((RANDOM_GEN_RANDMULT*last_rand1) + RANDOM_GEN_RANDCONST)
                                                        % RANDOM_GEN_RANDMAX;
         last_rand2 = ((RANDOM_GEN_RANDMULT*last_rand2) + RANDOM_GEN_RANDCONST)
                                                        % RANDOM_GEN_RANDMAX;

         retval = last_rand1+TOS_LOCAL_ADDRESS;

         if(last_rand2 > last_rand1){
            last_rand1 = (last_rand1 + last_rand2)%RANDOM_GEN_RANDMAX;
         }
      }

      return retval;
   }
}
