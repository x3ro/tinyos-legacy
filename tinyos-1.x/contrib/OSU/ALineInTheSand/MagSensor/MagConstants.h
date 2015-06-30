/**
 * Copyright (c) 2003 - The Ohio State University.
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs, and the author attribution appear in all copies of this
 * software.
 *
 * IN NO EVENT SHALL THE OHIO STATE UNIVERSITY BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE OHIO STATE
 * UNIVERSITY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * THE OHIO STATE UNIVERSITY SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE OHIO STATE UNIVERSITY HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS.
 */

#define SAMPLING_PERIOD_MILLIS  50
#define MOVING_WINDOW_SIZE      8
#define COUNTDOWN_TIME          1*(1000/SAMPLING_PERIOD_MILLIS)
#define NOISE                   0
#define AC                      1
#define DC                      2
#define LPF_WINDOW_SIZE         8
#define VARIANCE_WINDOW_SIZE    24
#define VARIANCE_THRESHOLD      18
#define MAX_HIST_SIZE		6

typedef struct
{
  uint32_t x;
  uint32_t y;
} Pair_uint32_t;

typedef struct
{
  int32_t x;
  int32_t y;
} Pair_int32_t;


typedef struct
{
    bool target_1;
    bool target_2;
    bool target_3;
    int8_t probability_1;
    int8_t probability_2;
    int8_t probability_3;
} TargetInfo_t;
