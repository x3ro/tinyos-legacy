/**
 * Global definitions for Crossbow sensor boards.
 *
 * @file      xsensors.h
 * @author    Martin Turon
 * @version   2004/3/10    mturon      Initial version
 *
 * Copyright (c) 2004 Crossbow Technology, Inc.   All rights reserved.
 * 
 * $Id: xsensors.h,v 1.1 2005/03/31 07:51:06 husq Exp $
 */

#ifndef __XSENSORS_H__
#define __XSENSORS_H__

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#include "xdb.h"
#include "SkyeReadMini/SkyeReadMini.h"
#include "SkyeReadMini/MiniResponse.h"
#include "SkyeReadMini/MiniCommand.h"


#ifdef __arm__
typedef unsigned char uint8_t;
typedef unsigned short uint16_t;
typedef unsigned int uint32_t;
#endif

/** 
 *  A unique identifier for each Crossbow sensorboard. 
 *
 *  Note: The sensorboard id is organized to allow for identification of
 *        host mote as well:
 *
 *  if  (sensorboard_id < 0x80)  // mote is a mica2dot
 *  if  (sensorboard_id > 0x7E)  // mote is a mica2
 *
 * @version   2004/3/10    mturon      Initial version
 */
typedef enum {
  // surge packet
  XTYPE_SURGE = 0x00,

  // mica2dot sensorboards 
  XTYPE_MDA500 = 0x01,   
  XTYPE_MTS510,
  XTYPE_MEP500,

  // mica2 sensorboards 
  XTYPE_MDA400 = 0x80,   
  XTYPE_MDA300,
  XTYPE_MTS101,
  XTYPE_MTS300,
  XTYPE_MTS310,
  XTYPE_MTS400,
  XTYPE_MTS420,
  XTYPE_MEP401,
} XbowSensorboardType;

typedef enum {
    AMTYPE_XUART      = 0x00,
    AMTYPE_MHOP_DEBUG = 0x03,
    AMTYPE_SURGE_MSG  = 0x11,
    AMTYPE_XSENSOR    = 0x32,
    AMTYPE_XMULTIHOP  = 0x33,
    AMTYPE_MHOP_MSG   = 0xFA,
    AMTYPE_RFID       = 0x51
} XbowAMType;

/** 
 * Reserves general packet types that xlisten handles for all sensorboards.
 *
 * @version      2004/4/2     mturon      Initial version
 */
typedef enum {
  // reserved packet ids 
  // reserved packet ids 
  XPACKET_ACK      = 0x40,
  XPACKET_W_ACK    = 0x41,
  XPACKET_NO_ACK   = 0x42,

  XPACKET_ESC      = 0x7D,    //!< Reserved for serial packetizer escape code.
  XPACKET_START    = 0x7E,    //!< Reserved for serial packetizer start code.
  XPACKET_TEXT_MSG = 0xF8,    //!< Special id for sending text error messages.
} XbowGeneralPacketType;

/** Encodes sensor readings into the data payload of a TOS message. */
typedef struct {
    uint8_t  board_id;        //!< Unique sensorboard id
    uint8_t  packet_id;       //!< Unique packet type for sensorboard
    uint8_t  node_id;         //!< Id of originating node
    uint8_t  parent;          //!< Id of node's parent
    uint16_t data[12];        //!< Data payload defaults to 24 bytes
    uint8_t  terminator;      //!< Reserved for null terminator 
} XbowSensorboardPacket;


#define XPACKET_MIN_SIZE            4  //!< minimum valid packet size

#define XPACKET_TYPE                2  //!< offset to type of TOS packet
#define XPACKET_GROUP               3  //!< offset to group id of TOS packet
#define XPACKET_LENGTH              4  //!< offset to length of TOS packet

#define XPACKET_DATASTART_STANDARD  5  //!< Standard offset to data payload
#define XPACKET_DATASTART_MULTIHOP  12 //!< Multihop offset to data payload
#define XPACKET_DATASTART           12 //!< Default offset to data payload

// Much easier to change arguments.
typedef void (*PacketPrinter)(XbowSensorboardPacket *packet);

typedef struct XPacketHandler {
    uint8_t  type;
    char *   version;
    // These can be wrapped in a union of different
    // types are needed.
    PacketPrinter print_parsed;
    PacketPrinter print_cooked;
    PacketPrinter export_parsed;
    PacketPrinter export_cooked;
    PacketPrinter log_cooked;
} XPacketHandler;

/* Linkage to main */
int xmain_get_verbose ();

/* Sensorboard data packet definitions */
void xpacket_print_raw     (unsigned char *tos_packet, int len);
void xpacket_print_parsed  (unsigned char *tos_packet);
void xpacket_print_cooked  (unsigned char *tos_packet);
void xpacket_export_parsed (unsigned char *tos_packet);
void xpacket_export_cooked (unsigned char *tos_packet);
void xpacket_log_cooked    (unsigned char *tos_packet);

void xpacket_initialize    ();
void xpacket_decode        (unsigned char *tos_packet, int len);
void xpacket_add_type      (XPacketHandler *handler);
void xpacket_print_output  (unsigned out_flags, unsigned char *tos_packet);
void xpacket_print_versions();
void xpacket_set_start     (unsigned offset);
int  xpacket_get_start     ();

/* Serial port routines. */
int xserial_port_open ();
int xserial_port_dump ();
int xserial_port_sync_packet  (int serline);
int xserial_port_read_packet  (int serline, unsigned char *buffer);
int xserial_port_write_packet (int serline, unsigned char *buffer, int len);

unsigned xserial_set_baudrate (unsigned baudrate);
unsigned xserial_set_baud     (const char *baud);
void     xserial_set_device   (const char *device);

/* Socket routines. */
int            xsocket_port_open    ();
void           xsocket_set_port     (const char *port);
unsigned       xsocket_get_port     ();
void           xsocket_set_server   (const char *server);
const char *   xsocket_get_server   ();

/* Sensorboard specific conversion routines. */
void mda300_initialize();    /* From boards/mda300.c */
void mda400_initialize();    /* From boards/mda500.c */
void mda500_initialize();    /* From boards/mda500.c */

void mts300_initialize();    /* From boards/mts300.c */
void mts310_initialize();    /* From boards/mts300.c */

void mts400_initialize();    /* From boards/mts400.c */
void mts420_initialize();    /* From boards/mts400.c */

void mts510_initialize();    /* From boards/mts510.c */
void mts101_initialize();    /* From boards/mts101.c */
void mep500_initialize();    /* From boards/mep500.c */
void mep401_initialize();    /* From boards/mep401.c */

void surge_initialize();     /* From boards/surge.c */

void skyetek_mini_initialize();

#endif  /* __SENSORS_H__ */



