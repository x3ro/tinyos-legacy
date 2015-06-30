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
  AM_DATAMSG = 117,
  AM_CHIRPMSG = 118,
  AM_CHIRPCOMMANDMSG = 119,
  AM_DATAOVERVIEWMSG = 120,
  AM_DATAREQUESTMSG = 121
};

enum {
  LEN_DATAMSG = 29,
  LEN_CHIRPMSG = 29,
  LEN_CHIRPCOMMANDMSG = 11,
  LEN_DATAREQUESTMSG = 9,
  LEN_DATAOVERVIEWMSG = 7
};

//receiverAction values
enum {
  SIGNAL_RANGING_INTERRUPT=1,
  STORE_TO_EEPROM=0,
  SEND_DATA_TO_UART=0x7e,
  BCAST_DATA=0xFFFF
};

enum {
  MAX_RSSI_MSGS=140,
  NUM_RSSI_PER_MSG=11
};

enum {
  RETURNING_RSSI_DATA=0,
  COLLECTING_RSSI_DATA=1,
  CHIRPING=2,
  IDLE=3
};

enum {
  OVERVIEW=0,
  ALL_RSSI=1,
  SOME_RSSI=2
};

struct ChirpMsg{
  uint16_t transmitterId;
  uint8_t msgNumber;
  uint16_t receiverAction;
  uint8_t rfPower;
  uint8_t empty[23];
} ;

typedef struct ChirpMsg ChirpMsg;


typedef struct  DataMsg  DataMsg;
struct  DataMsg{
  uint16_t transmitterId;
  uint16_t receiverId;
  uint8_t msgNumber;//this is the msg id of the sent message
  uint8_t msgIndex; //this is the order in which this message was received
  uint16_t rssi[NUM_RSSI_PER_MSG];
  uint8_t rfPower;
};

typedef struct  DataOverviewMsg  DataOverviewMsg;
struct  DataOverviewMsg{
  uint16_t transmitterId;
  uint16_t receiverId;
  uint16_t msgCnt;
  uint8_t rfPower;
};

typedef struct  ChirpCommandMsg ChirpCommandMsg;
struct  ChirpCommandMsg{
  uint8_t startStop;
  uint16_t transmitterId;
  uint8_t numberOfChirps;
  uint32_t timerPeriod;
  uint16_t receiverAction;
  uint8_t rfPower;
};

typedef struct  DataRequestMsg DataRequestMsg;
struct  DataRequestMsg{
  uint8_t startStop;
  uint8_t typeOfData;
  uint8_t msgIndex;
  uint32_t timerPeriod;
  uint16_t  receiverAction;
};







