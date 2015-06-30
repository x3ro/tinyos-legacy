/*
 * Copyright (c) 2007
 *	The President and Fellows of Harvard College.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 * 3. Neither the name of the University nor the names of its contributors
 *    may be used to endorse or promote products derived from this software
 *    without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE UNIVERSITY AND CONTRIBUTORS ``AS IS'' AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED.  IN NO EVENT SHALL THE UNIVERSITY OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 * OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 */

#ifndef MESCURYSAMPLING_H 
#define MESCURYSAMPLING_H
#include "MultiChanSampling.h" 

// (1) - Pin mappings
#ifdef PLATFORM_SHIMMER
  enum {
      MERCURY_CHAN_ACCX = 5,
      MERCURY_CHAN_ACCY = 4,
      MERCURY_CHAN_ACCZ = 3,
      MERCURY_CHAN_GYROX = 1,
      MERCURY_CHAN_GYROY = 6,
      MERCURY_CHAN_GYROZ = 2,
      MERCURY_CHAN_EMGRALL = 2,
      MERCURY_CHAN_EMGLALL = 1,
      MERCURY_CHAN_INVALID = 255,
  };
#else  // Assume TelosB
  enum {
      MERCURY_CHAN_ACCX = 0,
      MERCURY_CHAN_ACCY = 1,
      MERCURY_CHAN_ACCZ = 2,
      MERCURY_CHAN_GYROX = 6,
      MERCURY_CHAN_GYROY = 3,
      MERCURY_CHAN_GYROZ = 7,
      MERCURY_CHAN_INVALID = 255,
  };
#endif


// (2) - Type of sampling sensors
#ifdef SAMPLING_PLATFORM_EMG
  enum {MERCURY_SAMPLING_RATE = 512};  // in Hz
  enum {MERCURY_NBR_CHANS = 2};
  channelID_t MERCURY_CHANS[MERCURY_NBR_CHANS] = {MERCURY_CHAN_EMGRALL,
                                                  MERCURY_CHAN_EMGLALL};
#else  // assumie ACC and Gyro
  enum {MERCURY_SAMPLING_RATE = 100};  // in Hz
  enum {MERCURY_NBR_CHANS = 6};
  channelID_t MERCURY_CHANS[MERCURY_NBR_CHANS] = {MERCURY_CHAN_ACCX,
                                                  MERCURY_CHAN_ACCY,
                                                  MERCURY_CHAN_ACCZ,
                                                  MERCURY_CHAN_GYROX,
                                                  MERCURY_CHAN_GYROY,
                                                  MERCURY_CHAN_GYROZ};
#endif


#endif


