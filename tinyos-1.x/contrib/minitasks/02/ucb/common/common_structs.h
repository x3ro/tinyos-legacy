/* "Copyright (c) 2000-2002 The Regents of the University of California.  
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

// Authors: Cory Sharp
// $Id: common_structs.h,v 1.4 2003/01/07 09:29:57 cssharp Exp $

// Description: Common, simple data structures used throughout the NestArch.
// Oh, and a few macros, as well.

#ifndef _H_common_structs_h
#define _H_common_structs_h

// Pairs

typedef struct
{
  bool x;
  bool y;
} Pair_bool_t;

typedef struct
{
  uint8_t x;
  uint8_t y;
} Pair_uint8_t;

typedef struct
{
  uint16_t x;
  uint16_t y;
} Pair_uint16_t;

typedef struct
{
  int16_t x;
  int16_t y;
} Pair_int16_t;

typedef struct
{
  float x;
  float y;
} Pair_float_t;


// Triples

typedef struct
{
  bool x;
  bool y;
  bool z;
} Triple_bool_t;

typedef struct
{
  uint8_t x;
  uint8_t y;
  uint8_t z;
} Triple_uint8_t;

typedef struct
{
  uint16_t x;
  uint16_t y;
  uint16_t z;
} Triple_uint16_t;

typedef struct
{
  int16_t x;
  int16_t y;
  int16_t z;
} Triple_int16_t;

typedef struct
{
  float x;
  float y;
  float z;
} Triple_float_t;


#endif // _H_common_structs_h

