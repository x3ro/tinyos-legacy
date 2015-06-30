/*
* Copyright (c) 2014, Ege University, Izmir, Turkey & University of Padova, Padova, Italy
* All rights reserved.
*
* Redistribution and use in source and binary forms, with or without
* modification, are permitted provided that the following conditions
* are met:
*
* - Redistributions of source code must retain the above copyright
*   notice, this list of conditions and the following disclaimer.
* - Redistributions in binary form must reproduce the above copyright
*   notice, this list of conditions and the following disclaimer in the
*   documentation and/or other materials provided with the
*   distribution.
* - Neither the name of the copyright holders nor the names of
*   its contributors may be used to endorse or promote products derived
*   from this software without specific prior written permission.
*
* THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
* "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
* LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
* FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL
* THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
* INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
* (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
* SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
* HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
* STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
* ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
* OF THE POSSIBILITY OF SUCH DAMAGE.
*
* @author: K. Sinan YILDIRIM <sinanyil81@gmail.com>
*/

#if defined(PI_HDR_H)
#else
#define PI_HDR_H

#ifndef BEACON_RATE   // how often send the beacon msg (in seconds)
#define BEACON_RATE   10
#endif

#define MAX_PPM 100 // maximum parts per million, reported +/-100 ppm for MICAZ 

#if defined(PI_MICRO)
    #define ALPHA_MAX (1.0f/(((float)BEACON_RATE)*1000000.0f))
    #define E_MAX BEACON_RATE*2*MAX_PPM
#elif defined (PI_T32KHZ)
    #define ALPHA_MAX (1.0f/(((float)BEACON_RATE)*32000.0f))
    #define E_MAX BEACON_RATE*(2*MAX_PPM/32)  
#else
    #define ALPHA_MAX (1.0f/((float)BEACON_RATE))
    #define E_MAX 1  
#endif

#endif
