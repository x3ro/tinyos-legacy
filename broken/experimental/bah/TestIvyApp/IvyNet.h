/*								
 *
 *
 * "Copyright (c) 2002-2004 The Regents of the University  of California.  
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
 */
/*
 * Author:	Barbara Hohlt
 * Project: 	Ivy 
 *
 * Ivy Network Motes
 * Note: When running Nido, IVY_BASE_STATION_ADDR must be 0.
 * Note: When running mote, IVY_BASE_STATION_ADDR should not be 0.
 *
 *
 *
 */

//
// IVY_NETID is an Ivy network ID 
//	do not change
//
// IVY_APPID is an Ivy network ID 
// and must be unique accross applications.	
// For Ivy network motes only,
// 	IVY_APPID = IVY_NETID
//
//
// GET_SCHED is dependent on SLOT_FREQ
// and is the number of ticks until a
// power schedule is forwarded to the
// BTS. It's a bit of an art to set
// and behaves differently in Nido
// than the motes. Monitor must be
// set to TRUE.
//
// NUM_SLOTS and SLOT_FREQ are
// the number of slots per cycle
// and the duration of each slot
// in ms. These must be the same
// for ivy network motes and
// ivy application motes.
//
//
// AM_IVYMSG do not change.
// AM_IVYNET do not change.
// AM_IVYREQ do not change.
// AM_IVYADV do not change.
// AM_IVYACK do not change.
// AM_IVYLOG do not change.
// 
// IVY_DATA_LEN must be less than 21. 
// when TOSH_DATA_LENGTH = 29 in AM.h
//

bool PowerMgntOn = FALSE;
bool NidoHack = FALSE;
bool DummyDemand = FALSE;
bool SynchLeds = FALSE;
bool Monitor = FALSE;
bool SendLeds = FALSE;
bool InitLeds = TRUE;
bool TimeSynch = TRUE;
bool FaultTolerance = FALSE;

typedef enum {
  SLEEP_MODE,
  AWAKE_MODE,
  IDLE_MODE,
  TRANSMIT_MODE,
  RECEIVE_MODE,
  ADVERTISE_MODE 
} powermode ;

typedef enum {
  TRANSMIT,
  RECEIVE,
  ADVERTISE,
  TRANSMIT_PENDING,
  RECEIVE_PENDING,
  IDLE
} slotstate ;

enum {
  NUM_SLOTS = 40,
  BITMASK = 0x3F,
  BITSHIFT = 6,
  SLOT_FREQ = 80,
  SYNCH_FREQ = 750,
  LISTEN_PERIOD = 20,
  REQ_WAIT = 500,
  FAULT_FREQ = 750,
  GET_SCHED = 5000,
  TTL = 10,
  IVY_NETID = 7,
  IVY_APPID = 11,
  AM_IVYMSG = 21, 
  AM_IVYNET = 22, 
  AM_IVYREQ  = 23,
  AM_IVYADV  = 24,
  AM_IVYACK  = 25,
  AM_IVYLOG  = 26,
  IVY_DATA_LEN = 20,
  IVY_BASE_STATION_ADDR = 0x42,
  BTS_ADDRESS = 0x4D
};

typedef struct SlackerQueue {

  int in;
  int out;
  int count;
  uint32_t s[NUM_SLOTS];

} __attribute__ ((packed)) SlackerQueue;

typedef struct IvyNet {

    uint16_t mote_id;
    uint8_t ttl;
    uint8_t gradient;
    uint8_t hop_count;
    uint8_t cur_slot;
    uint8_t reserv_slot;

} __attribute__ ((packed)) IvyNet;


typedef struct IvyMsg {

    uint16_t myapp_id;
    uint16_t mymote_id;
    uint16_t app_id;
    uint16_t mote_id;
    uint8_t hop_count;
    uint8_t data[IVY_DATA_LEN];

} __attribute__ ((packed)) IvyMsg;
