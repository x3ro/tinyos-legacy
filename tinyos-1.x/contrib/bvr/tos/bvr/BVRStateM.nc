// ex: set tabstop=2 shiftwidth=2 expandtab syn=c:
// $Id: BVRStateM.nc,v 1.3 2005/11/18 00:39:01 rfonseca76 Exp $

/*                                                                      
 * "Copyright (c) 2000-2005 The Regents of the University  of California.  
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

/* This module takes care of maintaining the BVR state
   This includes the beacon flooding, coordinate flooding
   It has both end points for AM messages of type AM_BVR_BEACON_MSG
   Differently from previous versions, here there is no separate
   beacon flood: beacons just state that their coordinates are
   0 for themselves, and send the normal coordinate update. 
 ******************
 */

/* Comment on BEACON_ETX:
   BEACON_ETX defines another way of comparing the parent trees, based on ETX.
   ETX is the expected number of transmissions along the path, counting the
retransmissions at each hop. If p_i is the prob. of success at hop i,

   ETX = sum{1/p_i}

   q_i is the bidirectional quality of link i, and 1/pi = 255/qi

   To get around precision and rounding problems we transmit in the packet a
transformed cumulative ETX. Since ETX is at least one, the number of hops is
included in ETX, and we do not use in the ETX transmission. We reuse the field
'quality' in the packet, with 8 bits, to mean e', defined recursively as:
  
   e_0' = 0
   e_i' = (int) [e_{i-1}' + k*(255/q_i - 1) | 255] ([|255] caps it at 255)

  To compare paths we return to ETX from e_i'. h_i is the number of hops
along the path in question:
 
  e_i = e_i'/k +  h_i
  
  If we change the field to 16 bits, then it may be better to use 1/etx scaled
to the full 16 bits as the transmitted number. 

*/

includes AM;
includes BVR;
#ifdef FROZEN_COORDS
includes FrozenCoords;
#endif

includes BVRCommand;
includes topology;
includes nexthopinfo;


module BVRStateM {
  provides {
    interface StdControl;
    interface BVRNeighborhood;
    interface BVRLocator;
    interface BVRStateCommand;
    interface FreezeThaw;
  }
  uses {
    interface SendMsg as BVRStateSendMsg;
    interface ReceiveMsg as BVRStateReceiveMsg;

    interface Logger;

    interface Timer as BeaconTimer;
    interface Timer as BeaconRetransmitTimer;

    interface CoordinateTable;
    interface StdControl as CoordinateTableControl;

    interface LinkEstimator; 
    interface LinkEstimatorSynch;
    //LinkEstimator.StdControl is wired in LinkEstimatorComm

    interface Random;
  }
}

implementation {

/******************* Declarations *******************************/ 

enum {
  MY_DBG_ETX = DBG_USR2,
};
#ifdef BEACON_ETX
  enum {
    MAX_ETX = 255, 
    ETX_SCALE = 10, 
  };
#endif
#ifdef ETX_TOLERANCE
  enum {
    RESET_TOLERANCE = 128, //7 chances
  };
#define ETX_MD_FACTOR (2.0)
#endif

  uint32_t b_timer_int;
  uint32_t b_timer_jit;

  uint16_t delay_timer_jit;
  
  bool state_is_active;
  bool state_beaconing_coords;

  bool beacons_to_send;

  Coordinates my_coords;
  
  TOS_Msg beacon_buf;     //buffer to store beacons to be sent

  TOS_Msg rcv_beacon_buf; //local buff for buffer swapping for rcv'd beacons

  TOS_MsgPtr rcv_beacon_ptr;       //for rcv'd buffer swapping
  bool rcv_buffer_busy;
  
  BVRBeaconMsg *beacon_msg_ptr;       //for casting
  BVRBeaconMsgData *beacon_data_ptr; //for casting
  
  uint8_t beacon_msg_length; 
  bool beacon_send_busy;           //synchronize access to beacon_buf
  
  uint16_t beacon_seqno;
/* **/


/* Root Beacon info */
  BVRRootBeacon rootBeacons[N_ROOT_BEACONS];
  CoordsParents my_coords_parents;
  
  bool state_is_root_beacon;
  uint8_t root_beacon_id;
  uint8_t root_beacon_seqno;





/******************** Prototypes ********************************/

static void init_beacon_msg();
static void set_beacon_msg();

static void init_my_coords();

static void rootBeaconInit(BVRRootBeacon* b);

task void sendBeaconTask();

/******************** Init and Control *************************/  
  static void initialize() {
    int i;

    b_timer_int = I_BEACON_INTERVAL;
    b_timer_jit = I_BEACON_JITTER;
    
    beacons_to_send = 0;
  
    delay_timer_jit = I_DELAY_TIMER;

    beacon_send_busy = FALSE;
    rcv_buffer_busy = FALSE;

    state_beaconing_coords = TRUE;

    beacon_msg_length = sizeof(BVRBeaconMsg);
    beacon_seqno = 1;
    rcv_beacon_ptr = &rcv_beacon_buf;

    state_is_root_beacon = 
       (hc_root_beacon_id[TOS_LOCAL_ADDRESS] == INVALID_BEACON_ID) ? FALSE : TRUE;
    root_beacon_id = hc_root_beacon_id[TOS_LOCAL_ADDRESS];

    root_beacon_seqno = 1;

    init_beacon_msg();
#ifdef FROZEN_COORDS

    //Load my coordinates
    coordinates_copy( &frozen_coords[TOS_LOCAL_ADDRESS], &my_coords);
    
    for (i = 0; i < N_ROOT_BEACONS; i++) {
    
       //Load parent pointer
        my_coords_parents.parent[i]=frozen_coords_parents[TOS_LOCAL_ADDRESS].parent[i];
    
        //Set RootBeacons Info
        rootBeacons[i].valid=1;
        rootBeacons[i].parent=my_coords_parents.parent[i];
        rootBeacons[i].last_seqno=1;
        rootBeacons[i].hops=my_coords.comps[i];
        rootBeacons[i].combined_quality=250;
    
}
#else
  for (i = 0; i<N_ROOT_BEACONS; i++)
    rootBeaconInit(&rootBeacons[i]);
  init_my_coords();
#endif

      
  }
  
  command result_t StdControl.init() {
    result_t ok = FALSE;
    state_is_active = TRUE;
    initialize();
    dbg(DBG_USR2,"sizeof MAX_ROOT_BEACONS:%d Coords:%d AppMsg:%d BVRMsg:%d BVRCommandMsg:%d LoggingMsg:%d TOS_Msg:%d\n",
      MAX_ROOT_BEACONS, sizeof(Coordinates), sizeof(BVRAppMsg), sizeof(BVRBeaconMsg), sizeof(BVRCommandMsg), sizeof(BVRLogMsgWrapper), sizeof(TOS_Msg));
    dbg(DBG_USR2,"sizeof TOSH_DATA_LENGTH:%d app_data_length:%d ReverseLinkMsg:%d\n",
      TOSH_DATA_LENGTH, TOSH_DATA_LENGTH - (offsetof(BVRAppMsg,type_data) + offsetof(BVRAppData,data)), sizeof(ReverseLinkMsg));
    ok = call Random.init();
    call CoordinateTableControl.init();
    return ok;
  }
  
  command result_t StdControl.start() {
    dbg(DBG_USR2,"This is BVRStateM starting!\n");
    call CoordinateTableControl.start();
    if (state_beaconing_coords) {
      dbg(DBG_USR2,"Starting BeaconTimer\n");
      call BeaconTimer.start(TIMER_ONE_SHOT, b_timer_int);
    }
    return SUCCESS;
  }
  
  command result_t StdControl.stop() {
    call CoordinateTableControl.stop();
    return SUCCESS;
  }


  command result_t FreezeThaw.freeze() {
    dbg(DBG_USR2,"BVRStateM$freeze\n");
    state_is_active = FALSE;
    call BeaconTimer.stop();
    return SUCCESS;
  }
  
  command result_t FreezeThaw.thaw() {
    dbg(DBG_USR2,"BVRStateM$thaw\n");
    state_is_active = TRUE;
    if (state_beaconing_coords) {
      dbg(DBG_USR2,"Starting BeaconTimer\n");
      call BeaconTimer.start(TIMER_ONE_SHOT, b_timer_int);
    }
    return SUCCESS;
  }
  /****************** Internal Functions **************************/

   static uint8_t combine_quality(uint8_t q1, uint8_t q2) {
    return (q1+q2)>>1;
  }

  static uint8_t combine_root_quality(uint8_t q1, uint8_t q2) {
    uint8_t result;
    result = (uint8_t) (((q1/255.0)*(q2/255.0))*255); 
    dbg(DBG_USR2,"combine_root_quality: q1:%d, q2:%d, combined: %d\n",q1,q2,result);
    return result;
  }

#ifdef BEACON_ETX
  inline uint8_t scaledEtxFromQuality(uint8_t quality) {
    uint16_t etx;
    if (quality == 0 ) 
      return MAX_ETX;
    etx = (uint16_t)((255.0/quality - 1)*ETX_SCALE + 0.5);
    dbg(DBG_USR2,"scaled received quality %d, returning etx %d\n",quality,etx);
    etx = (etx > MAX_ETX)?MAX_ETX:etx;
    return (uint8_t)etx;
  }
#endif
  
  /**For suppressing repeated multihop messages*/
  static inline bool is_within_range(uint8_t _new, uint8_t old) {
    uint8_t range = (uint8_t) MSG_VALID_RANGE8;
    if (((uint8_t)(old + range)) < old) {
      return (_new > old || _new < ((uint8_t)(old + range)));
    } else {
      return (_new > old && _new < ((uint8_t)(old + range)));
    }
  }

  static inline uint8_t quality_with_retransmissions(uint8_t quality, uint8_t k) {
    float qi,qf;
    uint8_t q;
    int i;
    qi = ((255 - quality)/255.0);
    qf = qi;
    for (i = 1; i < k; i++) {
      qf = qf*qi;
    }
    //q = 255 - (uint8_t) (qf*255.0);
    q = (uint8_t)(255*( 1.0 - qf ));
    dbg(DBG_USR2,"quality_with_restransmissions(%d): %d -> %d\n", k, quality, q);
    return q;
  }
 

  /* Determine the minimum quality that has to be achieved to be
   * better than quality with the given threshold.
   * Relative, and threshold is treated as a fraction of 255! */
  inline uint8_t apply_threshold(uint8_t quality, uint8_t threshold) {
    uint8_t increase, difference, result;
    increase = (uint8_t) (1.0*quality * threshold/255.0);
    difference = 255 - quality;
    if (difference < increase)
      result = 255;
    else
      result = quality + increase;
    dbg(DBG_USR2,"COORDS: apply_threshold: (quality %d, threshold %d) -> %d\n",
      quality, threshold, result);
    return result;
  }

 
  /* 
   * Nothing in particular to do currently
   */
  static void init_beacon_msg() {
    beacon_msg_ptr = (BVRBeaconMsg*) &beacon_buf.data[0];
    beacon_data_ptr = (BVRBeaconMsgData*) &beacon_msg_ptr->type_data;
    return ;
  }

  /* 
   * Sets the beacon message with the coordinates from rootBeacons
   * and increments the sequence number
   * Note that the beacon sequence number is not incremented here
   */
  static void set_beacon_msg() {
    int i;
    BVRRootBeacon* b;
    uint8_t b_parent_ld;
    uint8_t quality_first,combined_quality = 0;
#ifdef BEACON_ETX
    uint8_t combined_etx; /* this is e_i' */
    uint8_t etx_first;    /* this is the scaled etx to the first node */
#endif
  
    beacon_data_ptr->seqno = beacon_seqno++;
    // the other option is to use the synchronize interface from the LinkEstimator
    // and store the value of the quality.
    for (i = 0; i < N_ROOT_BEACONS; i++) {
      b = &rootBeacons[i]; 
      if (b->hops != INVALID_COMPONENT) {
        beacon_data_ptr->beacons[i].hopcount = b->hops;
        beacon_data_ptr->beacons[i].seqno = b->last_seqno;

#ifdef BEACON_ETX
        /* Store ETX information. See comment above. We store (etx-1)*ETX_SCALE */
        if (state_is_root_beacon && i == root_beacon_id) {
          combined_etx = 0;
        } else {
          if (call LinkEstimator.find(b->parent, &b_parent_ld) != SUCCESS) { 
            /* if parent not in link table */
            combined_etx = MAX_ETX;
          } else if (call LinkEstimator.getBidirectionalQuality(b_parent_ld, &quality_first) != SUCCESS) {
            combined_etx = MAX_ETX;
          }
          if (quality_first > 0) {
            etx_first = scaledEtxFromQuality(quality_first);
            quality_first = etx_first;
            combined_etx = etx_first + b->combined_quality;
            if (combined_etx < etx_first) combined_etx = MAX_ETX; //if overflow
          } else {
            combined_etx = MAX_ETX;
          }
        }
        combined_quality = combined_etx;
#else
        /* Original combined quality info */
        if (state_is_root_beacon && i == root_beacon_id) {
          quality_first = 255;
          combined_quality = 255;
        } else {
          if (call LinkEstimator.find(b->parent, &b_parent_ld) != SUCCESS) { 
            /* if parent not in link table */
            dbg(DBG_USR2,"set_beacon_msg: ERROR: valid parent %d for root_id %d not in link table!\n",b->parent, i);
            quality_first = 0;
            combined_quality = 0;
          } else if (call LinkEstimator.getBidirectionalQuality(b_parent_ld, &quality_first) != SUCCESS) {
            quality_first = 0;
            combined_quality = 0;
          }
          if (quality_first > 0) {
            quality_first = quality_with_retransmissions(quality_first, 5);
            combined_quality = combine_root_quality(quality_first, b->combined_quality);
          }
        }
#endif
        beacon_data_ptr->beacons[i].quality = combined_quality;
        dbg(DBG_USR2,"set_beacon_msg: [%d] hops :%d last_seqno: %d comb_quality: %d (c:%d and 1st:%d)\n",
          i, beacon_data_ptr->beacons[i].hopcount, beacon_data_ptr->beacons[i].seqno,
          combined_quality, b->combined_quality, quality_first);
      } else {
        beacon_data_ptr->beacons[i].hopcount = INVALID_COMPONENT;
        dbg(DBG_USR2,"set_beacon_msg: [%d] - \n",i);
      }
    }
    dbg(DBG_USR2,"set_beacon_msg: seqno:%d my coordinates: ",beacon_data_ptr->seqno);
    coordinates_print(DBG_USR2,&my_coords);
  }
  
  /* RootBeacon related functions */
  static void rootBeaconInit(BVRRootBeacon* b) {
    if (b!=NULL) {
      b->valid = 0;
      b->parent = 0;
      b->hops = INVALID_COMPONENT; 
      b->last_seqno = 0;
#ifndef BEACON_ETX
      b->combined_quality = 0;
#else 
      b->combined_quality = MAX_ETX;
#endif
    } else
      dbg(DBG_ERROR,"rootBeaconInit called with NULL pointer\n");
  } 

  static void rootBeaconSetMyself(BVRRootBeacon *b) {
    if (b!=NULL) {
      b->valid = 1;
      b->parent = TOS_BCAST_ADDR;
      b->hops = 0;
      b->last_seqno = root_beacon_seqno;
#ifdef BEACON_ETX
      b->combined_quality = 0;
#else
      b->combined_quality = 255;
#endif
    } else 
      dbg(DBG_ERROR,"rootBeaconSetMyself called with NULL pointer\n");
  }

  /* Inits rootBeacon (if I'm a beacon), my_coords, my_coords_parents */
  static void init_my_coords() {
    int i;
    dbg(DBG_USR2,"init_my_coords: state_is_root_beacon:%d\n",state_is_root_beacon);
    coordinates_init(&my_coords);
    if (state_is_root_beacon) {
      coordinates_set_component(&my_coords,root_beacon_id,0);
      rootBeaconSetMyself(&rootBeacons[root_beacon_id]);
    }
    dbg(DBG_USR2,"init_my_coords:");
    coordinates_print(DBG_USR2,&my_coords);
    for (i = 0; i < N_ROOT_BEACONS; i++) {
      if (rootBeacons[i].valid) {
        my_coords_parents.parent[i] = rootBeacons[i].parent;
      } else {
        my_coords_parents.parent[i] = TOS_BCAST_ADDR;
      }
    }
  }


  /*Node addr has been dropped. See if it is our parent for any beacon, and in that
    case, drop it.
    In fact, our parent is never dropped, as the LinkEstimator pins down any node
    which is a parent. 
    A parent which dies is replaced when another node is chosen as a replacement parent */
  static void dropParent(uint8_t addr) {
    int i;
    
    for (i = 0; i < N_ROOT_BEACONS; i++) {
      if (rootBeacons[i].parent == addr) {
        dbg(DBG_USR2,"Dropping parent %d for root %d\n",addr,i);
        rootBeaconInit(&rootBeacons[i]);
        my_coords_parents.parent[i] = TOS_BCAST_ADDR;
      }
    }
  } 


  /* Updates the information regarding one specific beacon. 
   * If node 'from' is a better parent, then we update the
   * coordinates. We only update once per sequence number, and only
   * if we receive from the parent. If the parent dies, then its
   * quality will reach 0, and we shall replace it by some other 
   * neighbor.
   * Observation:
   *  0.we have to add 1 to the hopcount we receive. It is done here.
   *  1.if the hopcount does not change, it is safe to update, even if
   *    the seqno is the same. Also, the threshold for updates is not
   *    needed if the hopcount is the same 
   *  2.if we don't update the data, do not update the seqno, this may
   *    get tricky.
   */
  void updateRootBeacon(uint8_t root_id, uint16_t from, uint8_t quality, 
                        uint8_t seqno, uint8_t hopcount) { 

    //quality is what is received in the packet

    bool force_update = FALSE;  //in case there is no info or the current parent is not in the link table
    bool valid_seqno = FALSE;
    bool same_parent = FALSE;
    bool better_parent = FALSE;
    uint8_t from_ld;
    uint8_t current_parent_ld; //indices into the link estimator table
    uint8_t received_quality, received_combined_quality;
    uint8_t current_quality;
    uint8_t quality_update_threshold;
#ifndef BEACON_ETX
    uint8_t current_combined_quality, min_update_quality;
#endif
    bool current_parent_in_table;
    bool different_hop;

#ifdef BEACON_ETX
    uint8_t first_s_etx, combined_s_etx; //scaled etx values
    float received_combined_etx;       //true etx
    float current_combined_etx;        //true etx
    float etx_change_threshold;
#endif

    hopcount = hopcount + 1;

    if (root_id >= N_ROOT_BEACONS) {
      dbg(DBG_USR2,"ROOT: warning, received invalid root_id %d\n",root_id);
      return;
    }
    if (call LinkEstimator.find(from, &from_ld) != SUCCESS) {
      dbg(DBG_USR2,"ROOT: assertion failed: updateBeaconInfo received node %d not in LinkEstimator table\n",from); 
      return;
    }
    if (state_is_root_beacon && root_id == root_beacon_id) {
      dbg(DBG_USR2,"From myself, discarding\n");
      return;
    }


    /* get the quality of the incoming root message */
    if (call LinkEstimator.getBidirectionalQuality(from_ld, &received_quality) != SUCCESS) {
      received_quality = 0;
      dbg(DBG_USR2,"getBidirectionalQuality for %d failed, setting to 0\n",from);
    } else {
      dbg(DBG_USR2,"getBidirectionalQuality for %d returned %d\n",from,received_quality);
    }
#ifndef BEACON_ETX
    received_quality = quality_with_retransmissions(received_quality, 5);
    received_combined_quality = 
      combine_root_quality(received_quality, quality);
#else
    if (received_quality > 0) {
      first_s_etx = scaledEtxFromQuality(received_quality);
      combined_s_etx = first_s_etx + quality;
      if (combined_s_etx < first_s_etx) combined_s_etx = MAX_ETX; //if overflow
    } else {
      combined_s_etx = MAX_ETX;
    }

     /* Comparison needs to restore the actual etx values. The etx values
      * in the packet are only the 'extra' transmissions, they must be added to
      * the current hopcount of the path, after downscaled */

    received_combined_etx = (1.0*combined_s_etx)/ETX_SCALE + hopcount;
    received_combined_quality = quality;
    dbg(DBG_USR2,"UpdateRootBeacon: received etx:%d first_s_etx:%d (quality_fist:%d) combined_s_etx:%d ETX:%f\n",
               quality, first_s_etx, received_quality, combined_s_etx,received_combined_etx);
    
#endif
 
    dbg(DBG_USR2,"Root beacon message: source: %d seqno:%d hopcount:%d last_hop:%d comb.quality:%d\n",
                  root_id, seqno, hopcount, from, quality);
    call Logger.LogReceiveRootBeacon( seqno, root_id, from, hopcount, quality);


    if (!(rootBeacons[root_id].valid)) {
      /* don't know about this beacon, will update anyway */
      dbg(DBG_USR2,"Stored root beacon :     id: %d no info stored\n", root_id);
      force_update = TRUE;
    } else {
      /* we have info about this beacon */
      dbg(DBG_USR2,"Stored root beacon :     id: %d seqno:%d hopcount:%d last_hop:%d comb.quality:%d\n",
                    root_id, rootBeacons[root_id].last_seqno, rootBeacons[root_id].hops, 
                    rootBeacons[root_id].parent, rootBeacons[root_id].combined_quality);
      current_parent_in_table = (call LinkEstimator.find(rootBeacons[root_id].parent, &current_parent_ld) == SUCCESS);
      if (!current_parent_in_table) {
        dbg(DBG_USR2,"ROOT: force update: current parent %d not in LinkEstimator table\n", rootBeacons[root_id].parent);
        force_update = TRUE;
      } else {
        /* current parent is in link table */

        /* if same hopcount */
        /* Although it is apparently right (meaning we couldn't find a case
         * that breaks this, accepting the same sequence numbers makes breaking loops
         * that appear for some reason very hard */
        if (hopcount == rootBeacons[root_id].hops) {
           different_hop = FALSE;
          /* in this case we can use information with the same sequence number also */

          //valid_seqno = (seqno == rootBeacons[root_id].last_seqno ||
          //               is_within_range(seqno, rootBeacons[root_id].last_seqno));
          valid_seqno = is_within_range(seqno, rootBeacons[root_id].last_seqno);

          quality_update_threshold = 0;
          dbg(DBG_USR2,"ROOT: update: same hopcount, valid_seqno: %d threshold %d\n", 
              valid_seqno, quality_update_threshold);
        } else {
          different_hop = TRUE;
          valid_seqno = is_within_range(seqno, rootBeacons[root_id].last_seqno);
          quality_update_threshold = PARENT_SWITCH_THRESHOLD;
          dbg(DBG_USR2,"ROOT: update: different hopcount, valid_seqno: %d threshold: %d\n", 
              valid_seqno, quality_update_threshold);
        }
        

        /* if the same or a different parent */
        if (from == rootBeacons[root_id].parent) {
          same_parent = TRUE;
#ifdef BEACON_ETX
#ifdef ETX_TOLERANCE
          if (different_hop) {
            rootBeacons[root_id].tolerance = RESET_TOLERANCE;
            dbg(MY_DBG_ETX,"UpdateBeacon: same parent, different hop, reset tolerance: t[ %d ]= %d\n",root_id,rootBeacons[root_id].tolerance);
          } else {
            if (rootBeacons[root_id].tolerance < 255)
              rootBeacons[root_id].tolerance++;
            dbg(MY_DBG_ETX,"UpdateBeacon: same parent,   same hop, increase tolerance: t[ %d ]= %d\n",root_id,rootBeacons[root_id].tolerance);
          }
#endif //ETX_TOLERANCE
//This entire ifdef is here just for logging, unnecessary otherwise
          if (call LinkEstimator.getBidirectionalQuality(current_parent_ld,&current_quality) != SUCCESS) 
             current_quality = 0;
          if (current_quality > 0) {
            first_s_etx = scaledEtxFromQuality(current_quality);
            combined_s_etx = first_s_etx + rootBeacons[root_id].combined_quality;
            if (combined_s_etx < first_s_etx) combined_s_etx = MAX_ETX; //if overflow
          } else {
            combined_s_etx = MAX_ETX;
          }
          current_combined_etx = (1.0*combined_s_etx)/ETX_SCALE + rootBeacons[root_id].hops;
 
          //Logging for evaluation of hysteresis options
          //TODO: convert this to an actual log message, for the real testbed
              dbg(MY_DBG_ETX,"%d ETX root_id: %d CURRENT etx: %f hopcount: %d through: %d RECEIVED etx: %f hopcount: %d from: %d changed: %d\n",
                (int) (tos_state.tos_time / 4000), root_id,
                current_combined_etx, rootBeacons[root_id].hops, rootBeacons[root_id].parent,
                received_combined_etx, hopcount, from,
                (force_update || ( valid_seqno && ( same_parent || better_parent ))));
#endif
        } else if (valid_seqno) {
          /* compare the qualities, if different parent and valid sequence number */
          if (call LinkEstimator.getBidirectionalQuality(current_parent_ld,&current_quality) != SUCCESS) 
             current_quality = 0;
#ifndef BEACON_ETX
          current_quality  = quality_with_retransmissions( current_quality, 5);
          current_combined_quality =    
             combine_root_quality(current_quality, rootBeacons[root_id].combined_quality);
             min_update_quality = apply_threshold(current_combined_quality, quality_update_threshold);

          better_parent = (received_combined_quality > min_update_quality);
#else 
          if (current_quality > 0) {
            first_s_etx = scaledEtxFromQuality(current_quality);
            combined_s_etx = first_s_etx + rootBeacons[root_id].combined_quality;
            if (combined_s_etx < first_s_etx) combined_s_etx = MAX_ETX; //if overflow
          } else {
            combined_s_etx = MAX_ETX;
          }
          current_combined_etx = (1.0*combined_s_etx)/ETX_SCALE + rootBeacons[root_id].hops;
          dbg(DBG_USR2,"UpdateRootBeacon: current etx:%d first_s_etx:%d (quality_fist:%d) combined_s_etx:%d ETX:%f\n",
               quality, first_s_etx, current_quality, combined_s_etx, current_combined_etx);
         
          
          etx_change_threshold = 1.0*quality_update_threshold/(1.0*ETX_SCALE);
          better_parent = (received_combined_etx < current_combined_etx - etx_change_threshold );

#ifdef ETX_TOLERANCE
          //if better_parent and different_hop and tolerance over, switch

          if (better_parent) {
            if (different_hop) {
              rootBeacons[root_id].tolerance = (uint8_t)(rootBeacons[root_id].tolerance / ETX_MD_FACTOR);
              better_parent = (rootBeacons[root_id].tolerance == 0);
              if (rootBeacons[root_id].tolerance == 0) {
                rootBeacons[root_id].tolerance = RESET_TOLERANCE; //7 chances
                dbg(MY_DBG_ETX,"UpdateBeacon: diff parent, different hop, reset tolerance: t[ %d ]= %d\n",root_id,rootBeacons[root_id].tolerance);
              } else {
                dbg(MY_DBG_ETX,"UpdateBeacon: diff parent, different hop, decrease tolerance: t[ %d ]= %d\n",root_id,rootBeacons[root_id].tolerance);
              }
            } else {
              //better parent, same hop: increase tolerance
              if (rootBeacons[root_id].tolerance < 255)
                rootBeacons[root_id].tolerance++;
              dbg(MY_DBG_ETX,"UpdateBeacon: diff parent,   same hop, increase tolerance: t[ %d ]= %d\n",root_id,rootBeacons[root_id].tolerance);
            }
          }
#endif //ETX_TOLERANCE

          dbg(DBG_USR2,"UpdateRootBeacon: comparing ETX. Current etx %f hopcount %d . Received etx %f hopcount %d (threshold:%f)\n", 
              current_combined_etx, rootBeacons[root_id].hops, received_combined_etx, hopcount,etx_change_threshold);
  
          //Logging for evaluation of hysteresis options
          //TODO: convert this to an actual log message, for the real testbed
              dbg(MY_DBG_ETX,"%d ETX root_id: %d CURRENT etx: %f hopcount: %d through: %d RECEIVED etx: %f hopcount: %d from: %d changed: %d\n",
                (int) (tos_state.tos_time / 4000), root_id,
                current_combined_etx, rootBeacons[root_id].hops, rootBeacons[root_id].parent,
                received_combined_etx, hopcount, from,
                (force_update || ( valid_seqno && ( same_parent || better_parent ))));

#endif //BEACON_ETX
        }
      } //is current parent in the LinkEstimator table? (the answer will be yes)
    } //do we have info about this beacon?

#ifdef ETX_TOLERANCE
    if (force_update) {
      rootBeacons[root_id].tolerance = RESET_TOLERANCE; //7 chances
      dbg(MY_DBG_ETX,"UpdateBeacon: force update,   - -, reset tolerance: t[ %d ]= %d\n",root_id,rootBeacons[root_id].tolerance);
    }
#endif //ETX_TOLERANCE

    //XXX: RF: should we update seqno when we don't update the information?
    //     Initial thought says NO, it may get nasty if my parent becomes
    //     disconnected from the root.
    if (force_update || ( valid_seqno && ( same_parent || better_parent ))) {
       bool coordinates_changed, parent_changed;

      //do the update and the logging

      //These conditions assume that [! force_update => rootBeacons[root_id].valid]
      //and depend on short-circuit evaluation
      parent_changed      = (force_update || rootBeacons[root_id].parent != from);
      coordinates_changed = (force_update || rootBeacons[root_id].hops != hopcount);

      //logging
      if (!parent_changed) {
        dbg(DBG_USR2,"NGProcessRootBeacon: keeping parent for beacon %d\n", root_id);
      } else {
        dbg(DBG_USR2,"NGProcessRootBeacon: replacing parent for beacon %d\n",  root_id);
        if (rootBeacons[root_id].valid)
          dbg(DBG_USR2,"root_beacon_%d DIRECTED GRAPH: remove edge %d\n",root_id,
            rootBeacons[root_id].parent);
        dbg(DBG_USR2,"root_beacon_%d DIRECTED GRAPH: add edge %d\n",root_id,
            from);
      }

      rootBeacons[root_id].valid = TRUE;
      rootBeacons[root_id].parent = from;
      rootBeacons[root_id].last_seqno = seqno;
      rootBeacons[root_id].hops = hopcount; 
      rootBeacons[root_id].combined_quality = received_combined_quality;
      coordinates_set_component(&my_coords,root_id,hopcount);
      my_coords_parents.parent[root_id] = rootBeacons[root_id].parent;

      //log a change if either the coordinate or the parent changed
      if (coordinates_changed) {
        dbg(DBG_USR2,"COORDS: My Coordinates changed: ");
        coordinates_print(DBG_USR2,&my_coords);
        signal BVRLocator.statusChanged();
      }
      if (coordinates_changed || parent_changed) {
        call Logger.LogUpdateCoordinates(&my_coords,&my_coords_parents);
      }
 
      call Logger.LogUpdateCoordinate(root_id, rootBeacons[root_id].hops, 
         rootBeacons[root_id].parent,rootBeacons[root_id].combined_quality);

    }  
  } //end updateBeaconInfo





  /* This task processes received beacon messages.
   * Nodes learn both coordinates of other nodes and derive the root
   * beacon trees.
   * Update node info in coordinate table
   * For each valid coordinate
   *   update root beacon messages
   */
  task void processMessage() {
    /* will work from rcv_beacon_ptr */
    bool found = FALSE;
    BVRBeaconMsg * rcv_bvr_msg = (BVRBeaconMsg*)&rcv_beacon_ptr->data[0];
    BVRBeaconMsgData * rcv_bvr_data_ptr = (BVRBeaconMsgData*)&rcv_bvr_msg->type_data;
    BeaconInfo *beacon_info;
    int i;
    
    uint8_t neighbor;
    uint8_t quality;

    Coordinates received_coords;
    CoordinateTableEntry* ce;

    //Copy the received data into a Coordinates structure
    coordinates_init(&received_coords);
    for (i = 0; i < N_ROOT_BEACONS; i++) {
      if (rcv_bvr_data_ptr->beacons[i].hopcount != INVALID_COMPONENT) {
        beacon_info = &rcv_bvr_data_ptr->beacons[i];
        coordinates_set_component(&received_coords, i, beacon_info->hopcount);
      }
    }

    
    if (!rcv_buffer_busy) 
      dbg(DBG_ERROR,"Assertion failed: in processMessage, rcv_buffer_busy is false!!\n");

    if ((call LinkEstimator.find(rcv_bvr_msg->header.last_hop, &neighbor))==SUCCESS)
      found = TRUE;
    else 
      found = FALSE;

    if (found) {
      //the neighbor exists in the link info cache
      if (call LinkEstimator.getBidirectionalQuality(neighbor,&quality) != SUCCESS) 
        quality = 0;
    
      dbg(DBG_USR2,"NG$BVRStateReceiveMsg$receive: from %d \n", rcv_bvr_msg->header.last_hop);
          

      //discard message from ourselves
      if (rcv_bvr_msg->header.last_hop == TOS_LOCAL_ADDRESS) {
        //this will not actually happen
        dbg(DBG_USR2,"COORDS: Received beacon from myself, discarding\n");
      } else {
        dbg(DBG_USR2,"COORDS: Received coordinate beacon. last_hop:%d seqno:%d",
                    rcv_bvr_msg->header.last_hop, rcv_bvr_data_ptr->seqno);
        dbg(DBG_USR2," coords: ");
        coordinates_print(DBG_USR2,&received_coords);
  
        ce = call CoordinateTable.getEntry(rcv_bvr_msg->header.last_hop);
        if (ce == NULL) {
          //it is not in the table, let's try to store it
          dbg(DBG_USR2,"COORDS: Node is not in CoordinateTable\n");
          ce = call CoordinateTable.storeEntry(
                      rcv_bvr_msg->header.last_hop,
                      rcv_bvr_msg->header.last_hop,
                      rcv_bvr_data_ptr->seqno,
                      quality,
                      &received_coords);
          if (ce != NULL) {
            //it was successfully added to our table, and is fresh
            dbg(DBG_USR2,"COORDS: It is now\n");
          }
        } else {
          dbg(DBG_USR2,"COORDS: Node is in CoordinateTable, updating entry\n");
          //it is in our table already
          CTEntryTouch(ce);
          CTEntryUpdateCoordinates(ce, &received_coords);
          CTEntryUpdateSeqno(ce, rcv_bvr_data_ptr->seqno); 
          call Logger.LogUpdateNeighbor(ce);
        }               
        if (ce == NULL) {
          dbg(DBG_USR2,"COORDS: could not store entry in CoordinateTable\n");
          //XXX: we can decide whether or not we want to use this node as a potential
          //parent. I don't see why not...
        }

        /* ********************************************** */
        /* Now update the root beacon information for each valid beacon */
        /* ********************************************** */

#ifndef FROZEN_COORDS
        for (i = 0; i < N_ROOT_BEACONS; i++) {
          if (rcv_bvr_data_ptr->beacons[i].hopcount != INVALID_COMPONENT) {
            beacon_info = &rcv_bvr_data_ptr->beacons[i];
            updateRootBeacon(i, rcv_bvr_msg->header.last_hop, 
                             beacon_info->quality, beacon_info->seqno, 
                             beacon_info->hopcount);
          }
        }
#endif 

      } //if from myself (shouldn't happen at all)
    } //if found in LinkTable. Ignore if not found
    rcv_buffer_busy = FALSE; 
  } //end processMessage


  /* When a link is dropped by the link estimator, we should update the 
   * Coordinate table and the parent table.
   */
  event result_t LinkEstimatorSynch.linkRemoved(uint16_t addr) {
    if (state_is_active) {
      call CoordinateTable.removeEntry(addr);
#ifndef FROZEN_COORDS
      dropParent(addr);
#endif
    }
    return SUCCESS;
  }

  event result_t LinkEstimatorSynch.bidirectionalQualityChanged(uint16_t addr, uint8_t quality) {
    if (state_is_active)
      call CoordinateTable.updateQuality(addr, quality);
    return SUCCESS;
  }

  event result_t LinkEstimatorSynch.reverseQualityChanged(uint16_t addr, uint8_t reverseQuality) {
    return SUCCESS;
  }

  event result_t LinkEstimatorSynch.qualityChanged(uint16_t addr, uint8_t quality) {
    return SUCCESS;
  }

/****************** Provided Interface Commands *****************/  
  /* This function returns a set of next hop candidates to dest which have
   * distance smaller than min_dist.
   * The next_hop(s) in fallback mode are returned as well
   * The entries in nextHopInfo are ordered:
   *   - by distance
   *   - by quality
   * The fallback entries are located in the same list, after the normal mode
   * entries. 
   */
  command result_t BVRNeighborhood.getNextHops(Coordinates* dest, uint16_t dest_addr, 
                                              uint16_t min_dist, nextHopInfo* next_hops) {
    uint8_t closest_beacon;                                        
    if (dest == NULL || next_hops == NULL) {
      return FAIL;
    }

    if (call CoordinateTable.getNextHops(dest, dest_addr, min_dist, next_hops) == FAIL) {
     next_hops->n = 0;
    }

    dbg(DBG_ROUTE,"BVRNeighborhood$getNextHops: greedy returned %d next_hops\n",next_hops->n);
    /* Fill the fallback section with parental information */
    /* Discussion: maybe it is better to go to the coordinate table and
     * get all nodes that can make progress towards the root beacon, and
     * not only our parent. We are not doing this right now.
     */
    closest_beacon = coordinates_get_closest_beacon(dest);
    if (state_is_root_beacon && root_beacon_id == closest_beacon) {
      //I am the closest beacon, set TOS_LOCAL_ADDRESS as the next hop
      dbg(DBG_ROUTE,"BVRNeighborhood$getNextHops: fallback returned 1 next_hop, myself!\n");
      next_hops->f = 1;
      next_hops->next_hops[next_hops->n] = TOS_LOCAL_ADDRESS;
    } else if (closest_beacon == INVALID_COMPONENT ||
      //don't know how to get to the beacon
      !rootBeacons[closest_beacon].valid) {      
      dbg(DBG_ROUTE,"BVRNeighborhood$getNextHops: fallback returned 0 next_hops!\n");
      next_hops->f = 0;     
    } else {
      dbg(DBG_ROUTE,"BVRNeighborhood$getNextHops: fallback returned 1 next_hop!\n");
      next_hops->f = 1;
      next_hops->next_hops[next_hops->n] = rootBeacons[closest_beacon].parent;
    }
    return SUCCESS;
  }
 
   /* Returns my distance to the dest */
  command result_t BVRLocator.getDistance(Coordinates * dest, uint16_t * distance) {
    if (dest == NULL)
      return FAIL;
    *distance = coordinates_distance(&my_coords, dest, COORDS_DIST_WEIGHTED);
    dbg(DBG_ROUTE,"BVRLocator.getDistance result:%d here:");
    coordinates_print(DBG_ROUTE,&my_coords);
    dbg(DBG_ROUTE,"BVRLocator.getDistance dest:");
    coordinates_print(DBG_ROUTE,dest);
    return SUCCESS;
  }

     
  command result_t BVRLocator.getCoordinates(Coordinates * coords) {
    if (coordinates_count_valid_components(&my_coords) != 0) {
      coordinates_copy(&my_coords, coords);
      return SUCCESS;
    } else 
      return FAIL;
  }


  /* Will not allow eviction of a neighbor which is a parent to some beacon */
  event result_t LinkEstimator.canEvict(uint16_t addr) {
    int i;
    bool is_parent = FALSE;
    for (i = 0; i < N_ROOT_BEACONS; i++) {
      is_parent = (rootBeacons[i].parent == addr);
      if (is_parent)
        break;
    }
    return is_parent?FAIL:SUCCESS;
  }

/************************ BVRStateCommand**************************/

  /* This command is doing nothing */
  command result_t BVRStateCommand.setCoordinates(Coordinates * coords) {
    return SUCCESS;
  }
  
  command result_t BVRStateCommand.getCoordinates(Coordinates ** coords) {
    *coords = &my_coords;
    return SUCCESS;
  }
  
  command result_t BVRStateCommand.stopRootBeacon() {
    return SUCCESS;
  }

  command result_t BVRStateCommand.startRootBeacon() {
    return SUCCESS;
  }


  /* Use with care. It is not polite to have two beacons with the same id! */
  command result_t BVRStateCommand.setRootBeacon(uint8_t id) {
    if (id == NOT_ROOT_BEACON) {
      if (state_is_root_beacon) {
        state_is_root_beacon = FALSE;
      }
    } else {
      if (id > N_ROOT_BEACONS) {
        return FAIL;
      } else {
        if (!state_is_root_beacon) {
          state_is_root_beacon = TRUE;
          root_beacon_id = id;
          rootBeaconSetMyself(&rootBeacons[id]);
        }      
      }
    }
    return SUCCESS;
  }

  /* Value: NOT_ROOT_BEACON  indicates that the node is not a root beacon.
     Otherwise, the returned value is the root beacon id
  */
  command result_t BVRStateCommand.isRootBeacon(bool *value) {
    if (!state_is_root_beacon) 
      *value = NOT_ROOT_BEACON;
    else 
      *value = root_beacon_id;
    return SUCCESS;
  }
  
  command result_t BVRStateCommand.getNumNeighbors(uint8_t *n) {
    *n = call CoordinateTable.getOccupied();
    return SUCCESS;
  }
  
  command result_t BVRStateCommand.getRootInfo(uint8_t n, BVRRootBeacon** r) {
    if (n >= N_ROOT_BEACONS || r == NULL)
      return FAIL;
    *r =  &rootBeacons[n];
     return SUCCESS;
  }


/************************* Events ******************************/  
  //send beacon with my coordinates
  //We only beacon when our coordinates have changed. 
  //When this happens, we send two consecutive beacons
  event result_t BeaconTimer.fired() {
    int32_t jitter;
    uint32_t interval;

    if (state_beaconing_coords) {
      //will also log my coordinates
      call Logger.LogUpdateCoordinates(&my_coords,&my_coords_parents);
      jitter = ((call Random.rand()) % b_timer_jit) - (b_timer_jit >> 1);
      interval = b_timer_int + jitter;
      dbg(DBG_TEMP,"COORDS: beacon timer:jitter=%d. (max %d). Interval: %d\n"
                  ,jitter,b_timer_jit,interval);
      call BeaconTimer.start(TIMER_ONE_SHOT, interval);
    }

    if (beacons_to_send == 0) {
      //normal behavior
      //see if we should send a beacon
       beacons_to_send = 1;

       if (state_is_root_beacon) {
         rootBeacons[root_beacon_id].last_seqno = root_beacon_seqno++;
       }
       set_beacon_msg();  //sets the beacon message with coordinates, qualities, seqnos

     //send local coordinate beacon
     //if busy, just wait
     if (!beacon_send_busy) {
       post sendBeaconTask();
     }
   }
   return SUCCESS;
  }

  event result_t BeaconRetransmitTimer.fired() {
    post sendBeaconTask();
    return SUCCESS;
  }

  task void sendBeaconTask() {
    //assert beacon_send_busy is false
    if (beacon_send_busy) {
      dbg(DBG_USR2,"ERROR: assertion failed: beacon_send_busy should be false!\n");
      return;
    }
    dbg(DBG_USR2,"NG$BeaconTimer$fired: bcast beacon. seqno:%d to_send:%d\n",
       beacon_data_ptr->seqno,beacons_to_send);
    if (call BVRStateSendMsg.send(TOS_BCAST_ADDR, beacon_msg_length, &beacon_buf) == SUCCESS) {
      beacon_send_busy = TRUE;
    } else {
      //retry
      dbg(DBG_USR2,"Failure: send failed for beacon!\n");
      if (beacons_to_send > 0) {
        uint16_t delay = call Random.rand() % delay_timer_jit + 1;
        dbg(DBG_USR2,"Retrying\n");
        call BeaconRetransmitTimer.start(TIMER_ONE_SHOT,delay);
      }
    }
  }
 

  event result_t BVRStateSendMsg.sendDone(TOS_MsgPtr msg, result_t success) {
    dbg(DBG_USR2,"NG$BVRStateSendMsg$SendDone (%p): result=%s\n",msg,(success==SUCCESS)?"ok":"failure");
    if (msg == &beacon_buf) {
      dbg(DBG_USR2,"\t sent beacon buffer\n");
      beacon_send_busy = FALSE;
      beacons_to_send--;
      if (beacons_to_send > 0) {
        uint16_t delay = call Random.rand() % delay_timer_jit + 1;
        set_beacon_msg();
        call BeaconRetransmitTimer.start(TIMER_ONE_SHOT,delay);
      }
    }
//    if (success == SUCCESS) {
//      call Leds.redOff();
//    } else {
//      call Leds.redOn();
//    }
    return SUCCESS;
  }


  /* This is triggered when we receive a ngeo message
   *  1. update the link information
   *  2. update bidirectional link information (check hash)
   *  3. update my coordinates
   */

  event TOS_MsgPtr BVRStateReceiveMsg.receive(TOS_MsgPtr rcvMsg) {
    TOS_MsgPtr next_receive = rcv_beacon_ptr;
    rcv_beacon_ptr = (void*)0; //to guarantee that it breaks if there is a logical error

    dbg(DBG_USR2,"BVRStateReceiveMsg$receive: %p (rcv_beacon_ptr:%p)\n",rcvMsg,rcv_beacon_ptr);
    if (!state_is_active) {
      rcv_beacon_ptr = next_receive;
      return rcvMsg;
    }

    //drop message which was not for us
    if (rcvMsg->addr != TOS_LOCAL_ADDRESS &&
        rcvMsg->addr != TOS_BCAST_ADDR) {
      rcv_beacon_ptr = next_receive;
      return rcvMsg;
    }

    if (!rcv_buffer_busy) {
      post processMessage();
      rcv_beacon_ptr = rcvMsg;
      rcv_buffer_busy = TRUE;
      dbg(DBG_USR2,"BVRStateM$BVRStateReceiveMsg$receive: posting processMessage, rcv_beacon_ptr:%p\n",
          rcv_beacon_ptr);
    } else {
      //drop message, buffer is busy
      dbg(DBG_USR2,"Failure: BVRStateM$BVRStateReceiveMsg$receive:dropping message, busy processing\n");
      rcv_beacon_ptr = next_receive;
      next_receive = rcvMsg;
    }
    dbg(DBG_USR2,"BVRStateReceiveMsg$receive: returning %p\n",next_receive);
    return next_receive;
  }

} // end of implementation
 
