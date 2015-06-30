/*                                                                      tab:4
 * Copyright (c) 2003 Intel Corporation
 * All rights reserved Contributions to the above software program by Intel
 * Corporation is program is licensed subject to the BSD License, available at
 * http://www.opensource.org/licenses/bsd-license.html
 *
 */
/*
 * Authors:     Nithya Ramanathan
 *
 */

#ifndef __FAB_APP_MSG__
#define __FAB_APP_MSG__

#include "TosTime.h"

// Include S-MAC header defination
                                                                                
#include "SMACMsg.h"
#define APP_PAYLOAD_LEN (PHY_MAX_PKT_LEN - sizeof(AppHeader) - 2)
                                                                                
typedef struct {
        MACHeader hdr;   // include lower-layer header first
        uint8_t numTxBcast; // number of transmitted broadcast packets
    uint8_t numTxUcast; // number of transmitted unicast packets
} AppHeader;
                                                                                
                                                                                
typedef struct {
        AppHeader hdr;
        char data[APP_PAYLOAD_LEN];
        int16_t crc;   // crc must be the last field -- required by PhyRadio
} AppPkt;


enum {
  FABAPP_TS_MSG = 1,  
  FABAPP_HELP_MSG,  
  FABAPP_STATS_MSG,  
};

typedef struct {
  uint32_t time_offset_usec;
  bool ts_valid; // Indicates time-to-sleep is valid
  uint16_t time_to_sleep_msec; // negative values are possible!
  uint8_t current_state; // for robustness
  uint32_t time_until_time_synch_sec;
  uint32_t time_until_state_change_sec;

// Debuggnig Info
  uint16_t num_msgs_rx;
  uint16_t num_msgs_tx;
  int16_t send_delay;
  uint16_t preamble_len;
  int16_t stay_awake_time_msec;
  uint16_t num_ts_msgs_rcvd;
  uint16_t num_ts_msgs_expected;
  uint16_t num_ts_msgs_sent;
  uint16_t total_num_help_msgs_sent;
  bool ts_pending;
} __attribute ((packed)) fabAppTSMsg; 

typedef struct {
  uint16_t id; 
  uint16_t type; //fixme make uint8_t
  uint32_t time;
  // Pointer to the rest of the packet
  char pkt[0];
} __attribute ((packed)) fabAppMsg; 

typedef struct {
  uint16_t time_synch_period_hours;
  uint32_t wakeup_period_msec;
  uint64_t time_in_state_seconds;
  // Time to stay awake while send/rcv time-synchronization msgs
  uint32_t time_awake_during_ts_msec;
  uint8_t id;
} __attribute ((packed)) state_info;

#endif
