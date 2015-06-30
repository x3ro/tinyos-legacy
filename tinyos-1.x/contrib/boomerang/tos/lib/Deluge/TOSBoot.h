// $Id: TOSBoot.h,v 1.1.1.1 2007/11/05 19:11:24 jpolastre Exp $

/*									tab:2
 * "Copyright (c) 2000-2005 The Regents of the University  of California.  
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

/**
 * @author  Jonathan Hui <jwhui@cs.berkeley.edu>
 */

#ifndef __TOSBOOT_H__
#define __TOSBOOT_H__

#include "TOSBoot_platform.h"

/*
1. Problem: Need more flags in tosboot_args_t
2. Problem: The size of tosboot_args_t should not change
3. Observation: tosboot_args_t.noReprogram is an 8-bit bool
4. Solution: convert noReprogram to a 1-bit field, allowing for additional bit fields

5. Problem: Code compiled against the old TOSBoot.h uses the full 8-bit bool
     for noReprogram, accidentally setting additional bit flags
6. Problem: nesC does not correctly follow -I include directories for an #include
     within a header file
7. Observation: Most programs end up using the old, incorrect version of TOSBoot.h
8. Solution: Make the flags robust to being treated as an 8-bit bool by adding
     a "flagsAreValid" flag that is set to invalid when mistreated
*/

enum {
  TOSBOOT_FLAGS_VALID = (1 << 0),
  TOSBOOT_FLAGS_NOREPROGRAM = (1 << 1),
  TOSBOOT_FLAGS_NOPOWERDOWN = (1 << 2),
};


typedef struct tosboot_args_t {
  uint32_t imageAddr;
  uint8_t  gestureCount;
  union {
    bool noReprogram;
    bool flags;
  };
} tosboot_args_t;

#endif

