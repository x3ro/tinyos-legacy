/* Copyright (c) 2007, Marcus Chang, Klaus Madsen
   All rights reserved.

   Redistribution and use in source and binary forms, with or without
   modification, are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright notice,
      this list of conditions and the following disclaimer.

    * Redistributions in binary form must reproduce the above copyright notice,
      this list of conditions and the following disclaimer in the documentation
      and/or other materials provided with the distribution.

    * Neither the name of the Dept. of Computer Science, University of
      Copenhagen nor the names of its contributors may be used to endorse or
      promote products derived from this software without specific prior
      written permission.

   THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
   AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
   IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
   ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
   LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
   CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
   SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
   INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
   CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
   ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
   POSSIBILITY OF SUCH DAMAGE.
*/

/*
	Author:		Marcus Chang <marcus@diku.dk>
			Klaus S. Madsen <klaussm@diku.dk>
	Last modified:	March, 2007
*/

//#define DISABLE_FLASH

// Used in CompressionM, FlashManagerM
//#define MEMBUFSIZE 256
#define FLASH_PAGE_SIZE 256

/******************************************************************************
* Module: FlashManagerM
* Initiate offload when the number of pages with _data_ is more than this
* Note: flash pages are either: free, with data or need to be deleted
******************************************************************************/
#define CRITICAL_PAGE_LIMIT_STARTUP 7
#define CRITICAL_PAGE_LIMIT 1023

// Used in SamplingM
#define ACCEL_PERIOD 250 // 1/4th second

/******************************************************************************
* Module: CompressionM
* Do lossy compression when number of _free_ pages is _less_ than LOSSY_LIMIT
******************************************************************************/
#define COMPRESSION_SAMPLES_IN_AVERAGE 4
#define COMPRESSION_LOSSY_LIMIT 256
#define COMPRESSION_BUFFERS 18



#define CONTROLLER_LOOKBACK_SIZE 40
#define CONTROLLER_ERROR_THRESHOLD 10

