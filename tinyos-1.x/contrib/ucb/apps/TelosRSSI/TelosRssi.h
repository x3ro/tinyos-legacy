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
  //LEN_DATAMSG = 29, // this must be reduced on telos -mpm
  LEN_DATAMSG = 28,
  //LEN_CHIRPMSG = 29,
  LEN_CHIRPMSG = 6, // this must be reduced on telos -mpm
  //LEN_CHIRPCOMMANDMSG = 11, reduced this due to the reduced receiverAction -mpm
  LEN_CHIRPCOMMANDMSG = 10,
  // LEN_DATAREQUESTMSG = 9,  reduced this due to the reduced receiverAction -mpm
  LEN_DATAREQUESTMSG = 8,
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
  //MAX_RSSI_MSGS=140,
  MAX_MSGS=150, // should be called MAX_NUM_NODES? no, it's the max number of dataMsgs! 
               // it's (30 chirps/node)(2 readings/chirp)(1 dataMsg/12 readings)(30 nodes) = 150 dataMsgs 
               // we don't have the memory for that, so we'll store in eeprom.  for now
               // however, we just assume no more than 5 nodes so we just need 25 dataMsgs -mpm
  //NUM_RSSI_PER_MSG=11,
  NUM_RSSI_PER_MSG=10,  // should be called NUM_READINGS_PER_NODE? no, it's the number of readings 
                        // that we can stuff in a single packet.  on telos, this is:
                        // floor([TOSH_DATA_LENGTH - "overhead of a DataMsg"]/"bytes in a rssi+lqi reading")
                        // floor(28                - 7                       /2) = floor(21/2) = 10 -mpm
  NUM_LQI_PER_MSG=10
};

enum {
  RETURNING_RSSI_DATA=0,
  COLLECTING_RSSI_DATA=1,
  CHIRPING=2,
  IDLE=3
};

// various abstractions to clean up the code -mpm
enum {
  INITIAL_TIMER_PERIOD = 200,
  MAX_RF_POWER = 31, // TODO: add an ifdef for telos vs. mica2 
  // MAX_RF_POWER = 255,
};

enum { MY_FLASH_REGION_ID = unique("ByteEEPROM") }; 

enum {
  OVERVIEW=0,
  ALL_RSSI=1,
  SOME_RSSI=2
};

struct ChirpMsg{
  uint16_t transmitterId;
  //uint8_t msgNumber; increased from 8 to 16 -mpm
  uint16_t msgNumber;
  //uint16_t receiverAction; reduced from 16 to 8 -mpm
  uint8_t receiverAction;
  uint8_t rfPower;
  // uint8_t empty[23]; this isn't needed on telos
};

typedef struct ChirpMsg ChirpMsg;

typedef struct  DataMsg  DataMsg;
struct  DataMsg{
  uint16_t transmitterId;
  uint16_t receiverId;
  //uint8_t msgNumber; increased from 8 to 16 -mpm
  uint16_t msgNumber;//this is the msg id of the sent message  
  uint8_t rssi[NUM_RSSI_PER_MSG]; // i broke this into two arrays and dropped it down to one byte each -mpm
  uint8_t lqi[NUM_RSSI_PER_MSG]; // new for telos -mpm
  //uint16_t rssi[NUM_RSSI_PER_MSG];
  uint8_t rfPower;
  uint8_t msgIndex; //this is the order in which this message was received
};

typedef struct  DataOverviewMsg  DataOverviewMsg;
struct  DataOverviewMsg{
  uint16_t transmitterId;
  uint16_t receiverId;
  uint16_t msgCnt;
  uint8_t rfPower;
};

typedef struct  ChirpCommandMsg{
  uint16_t transmitterId;
  uint8_t startStop;
  uint8_t numberOfChirps;
  uint32_t timerPeriod;
  //uint16_t receiverAction; reduced this from 16 to 8 -mpm
  uint8_t receiverAction;
  uint8_t rfPower;
} ChirpCommandMsg;

typedef struct  DataRequestMsg DataRequestMsg;
struct  DataRequestMsg{
  uint8_t startStop;
  uint8_t typeOfData;
  uint8_t msgIndex;
  //uint16_t  receiverAction;  reduced this from 16 to 8
  uint8_t  receiverAction;
  uint32_t timerPeriod;
};







