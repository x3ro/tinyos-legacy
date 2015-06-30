/*									tab:4
 *  IMPORTANT: READ BEFORE DOWNLOADING, COPYING, INSTALLING OR USING.  By
 *  downloading, copying, installing or using the software you agree to
 *  this license.  If you do not agree to this license, do not download,
 *  install, copy or use the software.
 *
 *  Intel Open Source License 
 *
 *  Copyright (c) 2002 Intel Corporation 
 *  All rights reserved. 
 *  Redistribution and use in source and binary forms, with or without
 *  modification, are permitted provided that the following conditions are
 *  met:
 * 
 *	Redistributions of source code must retain the above copyright
 *  notice, this list of conditions and the following disclaimer.
 *	Redistributions in binary form must reproduce the above copyright
 *  notice, this list of conditions and the following disclaimer in the
 *  documentation and/or other materials provided with the distribution.
 *      Neither the name of the Intel Corporation nor the names of its
 *  contributors may be used to endorse or promote products derived from
 *  this software without specific prior written permission.
 *  
 *  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 *  ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 *  LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
 *  PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE INTEL OR ITS
 *  CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 *  EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 *  PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 *  PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 *  LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 *  NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 *  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * 
 */
/* 
 * Authors:  Kamin Whitehouse
 *           Intel Research Berkeley Lab
 *           UC Berkeley
 * Date:     8/20/2002
 *
 */

enum {
  AM_TOFCHIRPMSG = 114,
  AM_TOFRANGINGDATAMSG = 115,
  AM_TOFCHIRPCOMMANDMSG = 116
};

enum {
  LEN_TOFCHIRPMSG = 29,
  LEN_TOFCHIRPCOMMANDMSG = 12,
  LEN_TOFRANGINGDATAMSG = 14
};

enum {
  SIGNAL_RANGING_INTERRUPT=0,
  SEND_RANGING_TO_UART=0x7e,
  BCAST_RANGING=0xFFFF
};

enum {
  TOF_FILTER_BUFFER_SIZE=1
};

struct TofChirpMsg{
  uint16_t transmitterId;
  uint16_t sounderOffset;
  uint16_t sounderScale;
  uint16_t  receiverAction;
};

struct TofRangingDataMsg {
  uint16_t transmitterId;
  uint16_t receiverId;
  uint16_t distance;
  uint16_t sounderOffset;
  uint16_t sounderScale;
  uint16_t micOffset;
  uint16_t micScale;
};

struct TofChirpCommandMsg{
  uint16_t nodeid;
  uint8_t fromBase;
  uint8_t commandString[7];
  uint16_t chirpDestination;
  uint8_t maxNumChirps;
  uint16_t period;
  uint16_t  receiverAction;
};

/*typedef struct {
  uint8_t degree;
  uint16_t *coefficients;
} Polynomial;

void PolynomialEval(char* x, char* y, char* polynomial)
{
  uint16 i, val;
  *y=0;
  for(i=0;i<degree;i++)
    {
      *y+=x*((Polynomial*)polynomial->coefficients[i]^i);
    }
}

typedef Polynomial CalibrationCoefficients;*/

struct CalibrationCoefficients{
  uint16_t a;
  uint16_t b;
};







