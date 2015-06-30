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

//this does the same thing as DiagMsg.setBaseStation, but for the
//version of DiagMsg in tos/lib


enum {
  TOS_DEBUG_ADDR=0x7e, //this determines where the debug
			    //statements are sent
  VERBOSE=3 //this should be 0, 1, 2, 3, etc where zero is silent,
	    //higher numbers are more verbose
};
//!! Config 254 { uint8_t verbose = 3; }
//!! Config 253 { uint16_t debugAddr = 0xFFFA; }
//we have a enum for micaRangingApp, which doesn't use G_Config, and
//aG_Config for micaLocalizationApp, so we can change it during execution


enum{ RANGING_WINDOW_BUFFER_SIZE=10 };
typedef struct rangingBuffer_t{
  uint16_t buf[RANGING_WINDOW_BUFFER_SIZE];
} rangingBuffer_t;

enum {
  RECEIVING,
  NOT_RECEIVING
};

enum {
  TRANSMIT,
  RECEIVE
};

enum {
  AM_DIAGMSG=0xB1,
  AM_PULSE=194,
  AM_TRANSMITCOMMANDMSG=189,
  AM_ATMEGA8RESET=190,
  AM_SENSITIVITYMSG=195,
  AM_TOF=196,
  AM_CHIRPMSG=197,
  AM_TRANSMITMODEMSG=199,
  AM_TIMESTAMPMSG=198
};

typedef struct DiagMsg DiagMsg;
struct DiagMsg { //empty message creates mig packet that can hold anything
};

typedef struct TransmitCommandMsg TransmitCommandMsg;
struct TransmitCommandMsg { 
};

typedef struct TimestampMsg TimestampMsg;
struct TimestampMsg {
  uint16_t transmitterId;
  uint16_t timestamp;
};

typedef struct ChirpMsg  ChirpMsg;
struct ChirpMsg {
  uint16_t transmitterId;
  uint16_t rangingId;
  uint16_t batchNumber;
  uint16_t sequenceNumber;
  bool initiateRangingSchedule;
  uint8_t pad[20];
};

typedef struct SensitivityMsg  SensitivityMsg;
struct SensitivityMsg{
	uint8_t potLevel;
};

typedef struct TransmitModeMsg TransmitModeMsg;
struct TransmitModeMsg {
  uint8_t mode;
};

typedef struct EstReportMsg EstReportMsg;
struct EstReportMsg {
  uint16_t recvNode;
  uint16_t transmitterId;
  uint16_t timestamp;
};

enum {
  LEN_CHIRPMSG=sizeof(ChirpMsg),
  LEN_TRANSMITMODEMSG=sizeof(TransmitModeMsg),
  LEN_TIMESTAMPMSG=sizeof(TimestampMsg),
  LEN_ESTREPORTMSG=sizeof(EstReportMsg),
  LEN_SENSITIVITYMSG=sizeof (SensitivityMsg),
};

