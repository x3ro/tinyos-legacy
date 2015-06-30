/*
 * Copyright (C) 2002-2003 Dennis Haney <davh@diku.dk>
 * Copyright (C) 2003 Mads Bondo Dydensborg <madsdyd@diku.dk>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 */
/* Based on Blueware code */
#ifndef BT_ENUMS_H
#define BT_ENUMS_H

enum direction {
     DOWN = 0,
     UP = 1
};

enum btpacket_t {   // These should be well known by you, if you are reading this :P
     BT_NULL, BT_POLL, BT_FHS, BT_DM1, BT_DH1, BT_HV1, BT_HV2, BT_HV3, BT_DV, BT_AUX1,
     BT_DM3, BT_DH3, BT_DM5, BT_DH5, BT_ID, NUM_PKT_TYPES
};

enum packet_t {                 // Different packettypes
     PT_TCP,
     PT_UDP,
     PT_CBR,
     PT_AUDIO,
     PT_VIDEO,
     PT_ACK,
     PT_START,
     PT_STOP,
     PT_PRUNE,
     PT_GRAFT,
     PT_GRAFTACK,
     PT_JOIN,
     PT_ASSERT,
     PT_MESSAGE,
     PT_RTCP,
     PT_RTP,
     PT_RTPROTO_DV,
     PT_CtrMcast_Encap,
     PT_CtrMcast_Decap,
     PT_SRM,
     /* simple signalling messages */
     PT_REQUEST,
     PT_ACCEPT,
     PT_CONFIRM,
     PT_TEARDOWN,
     PT_LIVE,        // packet from live network
     PT_REJECT,

     PT_TELNET,      // not needed: telnet use TCP
     PT_FTP,
     PT_PARETO,
     PT_EXP,
     PT_INVAL,
     PT_HTTP,

     /* new encapsulator */
     PT_ENCAPSULATED,
     PT_MFTP,

     /* CMU/Monarch's extnsions */
     PT_ARP,
     PT_MAC,
     PT_TORA,
     PT_DSR,
     PT_AODV,
     PT_IMEP,

     // RAP packets
     PT_RAP_DATA,
     PT_RAP_ACK,

     PT_TFRC,
     PT_TFRC_ACK,
     PT_PING,

     // Diffusion packets - Chalermek
     PT_DIFF,

     // LinkState routing update packets
     PT_RTPROTO_LS,

     // MPLS LDP header
     PT_LDP,

     // GAF packet
     PT_GAF,

     // ReadAudio traffic
     PT_REALAUDIO,

     // Pushback Messages
     PT_PUSHBACK,

     // insert new packet types here
     PT_NTYPE // This MUST be the LAST one
};

enum state_t {
     STANDBY = 0,               // Obvious
     //NEW_CONNECTION, //unused
     CONNECTION,                // Connection established
     PAGE,                      // Paging a host
     PAGE_SCAN,                 // Scanning for pagers
     SLAVE_RESP,                // got a page in PAGE_SCAN, prepare to send reply
     SLAVE_RESP_ID_SENT,        // got a page in PAGE_SCAN, reply sent
     MASTER_RESP,               // found the host fra PAGE mode, TODO: I forgot what
                                // happens then :P
     INQUIRY,                   // Looking for hosts
     INQ_SCAN,                  // Scanning for inquerers
     INQ_RESP,                  // Replying to an inquiry
     NUM_STATE,                 // placeholder for the number of states there is
};


enum btmode {                   // TODO: Document
     Disconnected,
     Active,
     Hold,
     Sniff
};


enum clock_t {
     CLKN,                      // Running on native clock
     CLK                        // Running on masters clock
};

enum train_t {
     A,
     B
};

enum tdd_state_t {
     TRANSMIT,                  // Transmitting
     RECEIVE,                   // Recieving
     IDLE                       // Doing nothing special
};

enum state_progress_t {
     NONE_IN_PROG,              // Doing nothing
     INQ_IN_PROG,               // Inquiry in progress
     PAGE_IN_PROG,              // Paging
     LMP_IN_PROG,               // TODO: used in bt-lmp.cc
     HOLD_IN_PROG,              // sleeping
     SWITCH_IN_PROG,            // Switching master/slave role
     HOST_IN_PROG,              // TODO: used in tsf.cc
     NEW_CONN_IN_PROG,          // new connection in progress
     SCHED_IN_PROG,             // TODO: used in lcs.cc
};

enum device_role_t {
     AS_MASTER = 0x0001,
     AS_SLAVE  = 0x0002,
     BOTH      = 0x0003
};

enum timer_t {                  // TODO: document
     INQ_TM = 0,
     INQ_SCAN_TM,
     INQ_BACKOFF_TM,
     INQ_RESP_TM,
     PAGE_TM,
     PAGE_SCAN_TM,
     PAGE_RESP_TM,
     NEW_CONN_TM,
     //ALL_SCAN_TM, //unused
     HOST_TM,
     NUM_TM,                    // Placeholder for number of states
};

enum fhsequence_t {            // TODO: Document
     page_hopping,
     page_scan,
     slave_response,
     master_response,
     inquiry_hopping,
     inquiry_scan,
     inquiry_response,
     channel_hopping,
     num_sequence,              // Placeholder for number of entries
};

enum lmp_channel {
     LMP_CHAN = 0x03,
     L2CAP_CHAN = 0x0a,
     HOST_CHAN = 0x0f,
};

enum  link_policy {
     DIS_ALL = 0x00, // disable all
     EN_SWITCH = 0x01, // role switch
     EN_HOLD = 0x02,
     EN_SNIFF = 0x04,
     EN_PARK = 0x08,
     EN_CONN = 0x10, 	// The following operations should be turned on.
};

enum lmpproto_step{
     SEND_CMD,  // send command or request
     RECV_CMD,  // received cmmd or req
     SEND_ACCP, // send accept
     RECV_ACCP,
     SEND_REJ,  // send reject
     RECV_REJ,
};

enum lmp_opcode {
LMP_HOST_CONN_REQ=0,
LMP_QOS_REQ=1,
LMP_HOLD_REQ=2,
LMP_ACCEPTED=3,
// LMP_HOLD=4,
LMP_SLOT_OFFSET=5,
LMP_SWITCH_REQ=6,
LMP_DETACH=7,
LMP_NOT_ACCEPTED=8,
};

enum  hci_cmd {
     HCI_INQ = 0,
     HCI_INQ_SCAN,
     HCI_PAGE,
     HCI_PAGE_SCAN,
     NUM_HCI_CMD,
};


/**
 * Tasktype - used by the BTTaskScheduler. */
typedef enum task_type {
     INQ_TSK,
     INQ_SCAN_TSK,
     PAGE_TSK,
     PAGE_SCAN_TSK,
     COMM_TSK,
     NUM_TSK
} task_type;

/**
 * Task status - used by the BTTaskScheduler */
typedef enum {
	TASK_BEGIN, // Task has begun
	TASK_END,
	TASK_CANCEL,
} task_status;
#endif
