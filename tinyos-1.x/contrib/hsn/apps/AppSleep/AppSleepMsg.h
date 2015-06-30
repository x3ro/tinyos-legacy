/*                                                        tab:4
 * Copyright (c) 2003 Intel Corporation
 * All rights reserved Contributions to the above software program by Intel
 * Corporation is program is licensed subject to the BSD License, available at
 * http://www.opensource.org/licenses/bsd-license.html
 */
/*
 * Authors:     Nithya Ramanathan
 *
 */
                                                                                

#ifndef __FAB_APP_MSG__
#define __FAB_APP_MSG__

#include "TosTime.h"
#define DEBUGGING

enum {
  APPSLEEP_SYNCH = 1,  
  APPSLEEP_REQ_SYNCH,  
  APPSLEEP_STATS,  
};

typedef struct {
  uint32_t time_offset_usec;
  // Indicates time-to-sleep is valid. I think I dont 
  // need this eventually.
  bool ts_valid; 
  uint16_t time_to_sleep_msec; 
  uint32_t time_until_SYNCH_sec;
  // Used to change the sleep period
  uint32_t sleep_period_sec;
  // Current #hops that must be communicated across during one wake period
  // Nodes use this information to calculate receiver on time, so this 
  // is used to indicate a node has joined the network.
  uint8_t network_diameter; 

#ifdef DEBUGGING
  uint16_t num_msgs_rx; // 4,3 on 0016, should be 6,5
  uint16_t num_msgs_tx;
  int16_t send_delay;
  uint16_t preamble_len;
  int16_t stay_awake_time_msec;
  uint16_t num_ts_msgs_rcvd;
  uint16_t num_ts_msgs_expected; // 2,1 0032
  uint16_t num_ts_msgs_sent;
  uint16_t total_num_help_msgs_sent;
  bool ts_pending;
#endif
} __attribute ((packed)) AS_SYNCH; 

typedef struct {
  uint16_t id; 
//  uint8_t WAKE:1;
//  uint8_t FIN:1;
  uint16_t type; //fixme make uint8_t
  // Pointer to the rest of the packet
  char pkt[0];
} __attribute ((packed)) AS_Msg; 

typedef struct {
  uint16_t time_synch_period_hours;
  uint32_t wakeup_period_msec;
  uint64_t time_in_state_seconds;
  // Time to stay awake while send/rcv time-synchronization msgs
  uint32_t time_awake_during_ts_msec;
  uint8_t id;
} __attribute ((packed)) state_info;

#endif
