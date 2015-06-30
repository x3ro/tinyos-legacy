/**
 * Global definitions for TinyOS RF packet formation.
 *
 * @file      xpacket.h
 * @author    Martin Turon
 * @version   2004/10/3    mturon      Initial version
 *
 * Copyright (c) 2004 Crossbow Technology, Inc.   All rights reserved.
 * 
 * $Id: xpacket.h,v 1.4 2004/10/21 22:10:35 jdprabhu Exp $
 */

#ifndef __XPACKET_H__
#define __XPACKET_H__

#define XPACKET_MIN_SIZE            4  //!< minimum valid packet size

#define XPACKET_TYPE                2  //!< offset to type of TOS packet
#define XPACKET_GROUP               3  //!< offset to group id of TOS packet
#define XPACKET_LENGTH              4  //!< offset to length of TOS packet

#define XPACKET_DATASTART_STANDARD  5  //!< Standard offset to data payload
#define XPACKET_DATASTART_MULTIHOP  12 //!< Multihop offset to data payload
#define XPACKET_DATASTART           12 //!< Default offset to data payload

/** The standard header for all TinyOS active messages. */
typedef struct TOSMsgHeader
{
    uint16_t addr;
    uint8_t  type;
    uint8_t  group;
    uint8_t  length;
} __attribute__ ((packed)) TOSMsgHeader;

/** The standard marshalled header for XMesh, ReliableRoute, and Time_Sync */
typedef struct MultihopMsgHeader
{
    uint16_t sourceaddr;
    uint16_t originaddr;
    int16_t  seqno;
    uint8_t  hopcount;
} __attribute__ ((packed)) MultihopMsgHeader;

/** Bcast messages are quite simple; all they need is a sequence number. */
typedef struct BcastMsgHeader 
{
    uint16_t     seq_no;        //!< Required by lib/Broadcast/Bcast
} __attribute__ ((packed)) BcastMsgHeader;

/** Encodes sensor readings into the data payload of a TOS message. */
typedef struct {
    uint8_t  board_id;        //!< Unique sensorboard id
    uint8_t  packet_id;       //!< Unique packet type for sensorboard
    uint16_t parent;          //!< Id of node's parent
    uint16_t data[12];        //!< Data payload defaults to 24 bytes
    uint8_t  terminator;      //!< Reserved for null terminator 
} XbowSensorboardPacket;

/** 
 * Reserves general packet types that xlisten handles for all sensorboards.
 *
 * @version      2004/4/2     mturon      Initial version
 */
typedef enum {
  // reserved packet ids 
  // reserved packet ids 
  XPACKET_DOWNSTREAM = 0x0C,
  XPACKET_ACK      = 0x40,
  XPACKET_W_ACK    = 0x41,
  XPACKET_NO_ACK   = 0x42,
  XPACKET_ESC      = 0x7D,   //!< Reserved for serial packetizer escape code.
  XPACKET_SYNC     = 0x7E,   //!< Reserved for serial packetizer start code.

  XPACKET_TEXT_MSG = 0xF8,   //!< Special id for sending text error messages.
} XbowGeneralPacketType;

#endif
