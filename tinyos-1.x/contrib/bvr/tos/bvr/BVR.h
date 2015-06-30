// ex: set tabstop=2 shiftwidth=2 expandtab syn=c:
// $Id: BVR.h,v 1.2 2005/11/19 03:06:12 rfonseca76 Exp $
                                    
/*                                                                      
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
 * Authors:  Rodrigo Fonseca        
 * Date Last Modified: 2005/05/26
 */
#ifdef BEACON_ELECTION
#include "CBRouting_unslotted.h"
#endif

#ifndef BVR_ROUTING_H
#define BVR_ROUTING_H

#include "AM.h"
#include "util.h"
#include "topology.h"
#include "LinkEstimator.h"

#include "coordinates.h"


enum {
  AM_BVR_APP_MSG    = 55,//0x37
  AM_BVR_APP_P_MSG  = 54,//0x36
  AM_BVR_BEACON_MSG = 56,//0x38
};

#ifndef BVR_APP_DATA_LENGTH
#define  BVR_APP_DATA_LENGTH 1
#endif

//I_ stands for Initial
//Timings
enum {
  I_DELAY_TIMER = 250,  //delay for forwarding beacon messages
  I_RADIO_SETTING = 64, //mica2dot testbed:192 is fine. 0x70 for mica2's?
  I_BEACON_INTERVAL = 10000u,
  I_BEACON_JITTER = 10000u,
};

enum {
  PARENT_SWITCH_THRESHOLD = 15, //20% (was 30)
};

enum {
  NOT_ROOT_BEACON = 255,
};

typedef struct {
  bool valid;
  uint16_t parent;
  uint8_t last_seqno;
  uint8_t hops;
  uint8_t combined_quality; //stores the quality combined quality from the parent up to the root
#ifdef ETX_TOLERANCE
  uint8_t tolerance;
#endif
} BVRRootBeacon;

typedef struct {
  uint16_t parent[MAX_ROOT_BEACONS];
} CoordsParents;

#include "coordinate_table_entry.h"

enum {
  BVR_APP_MODE_FALLBACK_MASK = 0x80
};

enum {
  MSG_VALID_RANGE8 = 128      //Valid range for sequence numbers with 8 bits
};

/*Metrics for Routing*/
enum {
  METRIC_CLOSEST_BEACON = 6,
};

typedef struct {
  uint8_t data[BVR_APP_DATA_LENGTH];
} __attribute__ ((packed)) BVRData;


/* Used for AM_BVR_APP_MSG, carries application data multihop.
 * BVRRouter uses this structure for storing the multihop routing data
 */

typedef struct {       //for AM_BVR_APP_MSG, carries application data multihop
  uint8_t hopcount;
  Coordinates dest;
  uint16_t dest_id;
  uint16_t  origin;       //the originator of the message
  uint8_t mode;           //most significant bit: fallback? other 7: current mode
  uint16_t fallback_thresh; //the value of the main metric when entering fallback
  uint16_t msg_id;
  BVRData data;  
} __attribute__ ((packed)) BVRAppData;

/* This struct is the same as the above but has an extra field - slot - that
   allows parametrization of the interface provided by BVRRouter */
typedef struct {       //for AM_BVR_APP_P_MSG, carries application data multihop
  uint8_t hopcount;
  Coordinates dest;
  uint16_t dest_id;
  uint16_t  origin;       //the originator of the message
  uint8_t mode;           //most significant bit: fallback? other 7: current mode
  uint16_t fallback_thresh; //the value of the main metric when entering fallback
  uint8_t slot;           //added for demultiplexing
  uint16_t msg_id;
  BVRData data;  
} __attribute__ ((packed)) BVRAppPData;



/* New BVRBeaconMsg that incorporates both beacon and root beacon
 * messages into one periodic transmission 
 * This message will only go 1 hop away */

/* sizeof = 3 */
typedef struct BeaconInfo {
  uint8_t hopcount;
  uint8_t seqno;
  uint8_t quality;
} __attribute__ ((packed)) BeaconInfo;

//sizeof = 3 + MAX_ROOT_BEACONS*3. For B=5, 3 + 15 = 18 bytes.
//For B=8, 3+24 = 27, B=12, 3+36 = 39
typedef struct {
  uint16_t seqno;        //the sequence number of my beacon messages
  BeaconInfo beacons[MAX_ROOT_BEACONS] ;
} __attribute__ ((packed)) BVRBeaconMsgData;


//size: 4 + sizeof(BeaconMsgData). B=5, 22; B=8, 31, B=12, 43
typedef struct BVR_Beacon_Msg {
  LEHeader header;
  BVRBeaconMsgData type_data;
} __attribute__ ((packed)) BVRBeaconMsg;
 

typedef struct BVR_Raw_Msg {
  LEHeader header;
} __attribute__ ((packed)) BVRRawMsg;


typedef struct BVR_App_Msg{
  LEHeader header;
  BVRAppData type_data;  
} __attribute__ ((packed)) BVRAppMsg;

typedef struct BVR_App_P_Msg{
  LEHeader header;
  BVRAppPData type_data;  
} __attribute__ ((packed)) BVRAppPMsg;


/***/
#endif  //BVR_ROUTING_H
