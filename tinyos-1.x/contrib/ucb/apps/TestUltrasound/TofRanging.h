/*									tab:4
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
 * Copyright (c) 2002-2003 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
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







