/*                                                                      tab:4
 *  IMPORTANT: READ BEFORE DOWNLOADING, COPYING, INSTALLING OR USING.  By
 *  downloading, copying, installing or using the software you agree to
 *  this license.  If you do not agree to this license, do not download,
 *
 */
/*                                                                      tab:4
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
 */
/*                                                                      tab:4
 * Copyright (c) 2003 Intel Corporation
 * All rights reserved Contributions to the above software program by Intel
 * Corporation is program is licensed subject to the BSD License, available at
 * http://www.opensource.org/licenses/bsd-license.html
 *
 */
/*
 * Authors:	Mark Yarvis, Nandu Kushalnagar, Jasmeet Chhabra
 *
 */

// active message id's are used to distinguish single-hop messages
enum {
   AM_ID_FLOOD = 2,  // FLOOD data packet

   AM_ID_DSDV = 3,        // DSDV data packet
   AM_ID_DSDV_SOI = 4,    // DSDV data packet with source sphere id

   AM_ID_DSDV_RUPDATE_HOPS = 5,    // DSDV rupdate with hop count metric
   AM_ID_DSDV_RUPDATE_QUALITY = 6, // DSDV rupdate with quality metric
   AM_ID_DSDV_RUPDATE_SOI = 7,     // DSDV rupdate with SoI metric
   AM_ID_DSDV_RUPDATE_CLUSTER = 9, // DSDV rupdate with clustering

   AM_ID_DSDV_RUPDATE_REQ = 8,  // DSDV rupdate request

   AM_ID_AODV = 9,         // AODV data packet


   AM_ID_AODV_RREQ = 10,   // AODV route request
   AM_ID_AODV_RREPLY = 11,   // AODV route reply  
   AM_ID_AODV_RERR = 12,   // AODV route reply  

   AM_ID_AODV_RREQ_HOPS = 13,
   AM_ID_AODV_RREPLY_HOPS = 14,
   AM_ID_AODV_RERR_HOPS = 15,
   AM_ID_SOURCEROUTE = 16,
   AM_ID_RT_ACK = 17,
   AM_ID_FAB_TMP_DATA_CAP = 18 // this is a temp message used to initiate capture until we do not have power saving protocol integrated
};

// application id's are used to distinguish multi-hop messages
enum {
   APP_ID_SETTINGS = 2,
   APP_ID_TRACEROUTE = 3,
   APP_ID_TRACEROUTE_SOI = 4,
   APP_ID_SOURCEROUTE =5,
   APP_ID_AODV_TEST = 6,
   APP_ID_CONF_ROOM_STATUS = 7,
   APP_ID_CONF_ROOM_RESERVATION = 8,
   APP_ID_CONF_ROOM_RES_BEACON = 9,
   APP_ID_CLUSTER_SLEEP = 10,
   APP_ID_RELIABLE_TRANSPORT = 11, // special app for reliable transport protocol
   APP_ID_FAB_TMP_DATA_CAP = 12 //  temp for data cap msg in fab app
};

// reliable app id's are used to demultiplex between apps using the reliable transport protocol
enum {
  RELIABLE_APP_ID_DATA_TRANSFER = 2,
  RELIABLE_APP_ID_STATS_TRANSFER
};


typedef struct {
   wsnAddr src;
   uint8_t seq;
   uint8_t data[1]; // start of payload; size is not known at compile time
} SHop_Msg;

typedef SHop_Msg *SHop_MsgPtr;

typedef union {
   SHop_MsgPtr msg;
   uint8_t* bytes;
} SHop_MsgPtr_u;

typedef struct {
   wsnAddr src;
   wsnAddr dest;
   uint8_t app;
   wsnAddr length;
} MHop_Header;

typedef struct {
   MHop_Header mhop;
   uint8_t seq;
   uint8_t ttl;
   uint8_t data[1]; // start of payload; size is not known at compile time
} Flood_Msg;

typedef Flood_Msg *Flood_MsgPtr;

typedef union {
   Flood_MsgPtr msg;
   uint8_t* bytes;
} Flood_MsgPtr_u;

typedef struct {
   MHop_Header mhop;
   uint8_t seq;
   uint8_t ttl;
   uint8_t data[1]; // start of payload; size is not known at compile time
} DSDV_Msg;

typedef DSDV_Msg *DSDV_MsgPtr;

typedef union {
   DSDV_MsgPtr msg;
   uint8_t* bytes;
} DSDV_MsgPtr_u;

typedef struct {
   wsnAddr dest;
   uint8_t seq;
   uint8_t metric[1];  // space for the metric(s) and piggyback info
} DSDV_Rupdate_Msg;

typedef DSDV_Rupdate_Msg *DSDV_Rupdate_MsgPtr;

typedef union {
   DSDV_Rupdate_MsgPtr msg;
   uint8_t* bytes;
} DSDV_Rupdate_MsgPtr_u;


typedef struct {
   MHop_Header mhop;
   uint8_t seq;
   uint8_t ttl;
   uint8_t data[1]; // start of payload; size is not known at compile time
} AODV_Msg;

typedef AODV_Msg *AODV_MsgPtr;

typedef struct {
  wsnAddr dest;
  wsnAddr src;
  uint16_t  rreqID;
  uint16_t srcSeq;   // seq# used for storing entries back to the source
  uint16_t destSeq; // seq# last received from the destination by the source
  uint8_t metric[1]; 
  uint8_t data[1];  
} AODV_Rreq_Msg;

typedef AODV_Rreq_Msg* AODV_Rreq_MsgPtr;

typedef struct {
  wsnAddr dest;
  wsnAddr src;
  uint16_t destSeq;
  uint8_t metric[1]; 
  uint8_t data[1];  
} AODV_Rreply_Msg;

typedef AODV_Rreply_Msg* AODV_Rreply_MsgPtr;

typedef struct {
  wsnAddr dest;
  uint16_t destSeq;
  uint8_t data[1];
} AODV_Rerr_Msg;

typedef AODV_Rerr_Msg* AODV_Rerr_MsgPtr; 




typedef struct{
  uint8_t cmd;
  uint8_t seq;
  wsnAddr src;
  wsnAddr dest;
  uint8_t sensor;
  uint8_t dataSet;
  uint8_t data[1];
}DataCapCmdMsg;

enum {  //CMD types for data cap message
  DATA_CAP_INIT = 15,
  DATA_CAP_ACK  = 16
};

typedef DataCapCmdMsg* DataCapCmdMsgPtr;

typedef __attribute__((packed)) struct{
  uint16_t sensor;
  uint16_t len;
  uint32_t timestamp;
  uint8_t data[1];
}SensorSampleHeader;

typedef SensorSampleHeader* SensorSampleHeaderPtr;

typedef __attribute__((packed)) struct{
  uint8_t mtc;
  uint8_t appId;
  uint8_t tId;
} RelHeader;
typedef RelHeader* RelHeaderPtr;

 
typedef __attribute__((packed)) struct{
  RelHeader rHead;
  uint8_t  ver;
  __attribute__ ((packed)) uint16_t dataSize;
  __attribute__ ((packed)) uint16_t fragSize;
  __attribute__ ((packed)) uint16_t fragPeriod;
  __attribute__ ((packed)) uint16_t netDelay;
  uint8_t  winSize;
  uint8_t data[1];
}RelConnReq;
typedef RelConnReq* RelConnReqPtr;

typedef  __attribute__ ((packed)) struct{
  RelHeader rHead;
  __attribute__ ((packed)) uint16_t dataSize;
  __attribute__ ((packed)) uint16_t fragSize;
  __attribute__ ((packed)) uint16_t nackPeriod;
  uint8_t  winSize;
  uint8_t data[1];
}RelConnAcc;
typedef RelConnAcc* RelConnAccPtr;

typedef __attribute__((packed)) struct{
  RelHeader rHead;
  uint8_t reasonCode;
  uint8_t data[1];
}RelConnRej;
typedef RelConnRej* RelConnRejPtr;

typedef __attribute__((packed)) struct{
  RelHeader rHead;
  __attribute__ ((packed)) uint16_t fragIndex;
  uint8_t data[1];
}RelData;
typedef RelData* RelDataPtr;

typedef __attribute__((packed)) struct{
  RelHeader rHead;
  uint8_t seq;
  __attribute__ ((packed)) uint16_t startFrag;
  uint8_t data[1];
}RelNack;
typedef RelNack* RelNackPtr;

typedef __attribute__((packed)) struct{
  RelHeader rHead;
  uint8_t data[1];
}RelLastAck;
typedef RelLastAck* RelLastAckPtr;

typedef __attribute__((packed)) struct{
  RelHeader rHead;
  uint8_t data[1];
}RelRecLastAck;
typedef RelRecLastAck* RelRecLastAckPtr;

enum {
   SHOP_HEADER_LEN = offsetof(SHop_Msg, data),
   FLOOD_HEADER_LEN = offsetof(Flood_Msg, data),
   DSDV_HEADER_LEN = offsetof(DSDV_Msg, data),
   AODV_HEADER_LEN = offsetof(AODV_Msg, data), //temp stuff
   AODV_RREQ_HEADER_LEN   = offsetof(AODV_Rreq_Msg, data),
   AODV_RREPLY_HEADER_LEN = offsetof(AODV_Rreply_Msg, data),
   AODV_RERR_HEADER_LEN = offsetof(AODV_Rerr_Msg, data),
   DSDV_RUPDATE_HEADER_LEN = offsetof(DSDV_Rupdate_Msg, metric),
   DATA_CAP_MSG_LEN        = offsetof(DataCapCmdMsg, data),
   SENSOR_SAMPLE_HEADER_LEN = offsetof(SensorSampleHeader, data),
   REL_CONN_REQ_LEN  = offsetof(RelConnReq, data),
   REL_CONN_ACC_LEN  = offsetof(RelConnAcc, data),
   REL_CONN_REJ_LEN  = offsetof(RelConnRej, data),
   REL_DATA_LEN      = offsetof(RelData, data),
   REL_NACK_LEN      = offsetof(RelNack, data),
   REL_LAST_ACK_LEN  = offsetof(RelLastAck, data),
   REL_REC_LAST_ACK_LEN  = offsetof(RelRecLastAck, data)
   //   AODV_RUPDATE_HEADER_LEN = offsetof(AODV_Rupdate_Msg, metric) //temp stuff
};

