/**
 * Global definitions for Crossbow sensor boards.
 *
 * @file      xsensors.h
 * @author    Martin Turon
 * @version   2004/3/10    mturon      Initial version
 *
 * Copyright (c) 2004 Crossbow Technology, Inc.   All rights reserved.
 * 
 * $Id: xcommand.h,v 1.4 2004/10/08 20:59:02 mturon Exp $
 */

#ifndef __XSENSORS_H__
#define __XSENSORS_H__

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#ifdef __arm__
typedef unsigned char uint8_t;
typedef unsigned short uint16_t;
typedef unsigned int uint32_t;
#endif

#include "xapps.h"
#include "xpacket.h"

/* Linkage to main */
int xmain_get_verbose ();

//extern int    g_frame;
extern int       g_seq_no;
extern unsigned  g_dest;
extern unsigned  g_group;
extern char *    g_argument;


void xcrc_set(char *packet, int length);

/* Sensorboard data packet definitions */
void        xpacket_print_raw     (unsigned char *tos_packet, int len);
void        xpacket_print_ascii   (unsigned char *tos_packet, int len);

void        xpacket_initialize    ();
void        xpacket_print_time    ();
void        xpacket_print_versions();

void        xpacket_add_type      (XAppHandler *handler);
XAppHandler *xpacket_get_app      (uint8_t app);
XCmdBuilder xpacket_get_builder   (uint8_t app, char *cmd);
int         xpacket_build_cmd     (char *buffer, XCmdBuilder cmd_bldr, int sf);

/* Serial port routines. */
int xserial_port_open ();
int xserial_port_dump ();
int xserial_port_sync_packet (int serline);
int xserial_port_read_packet (int serline, char *buffer);
int xserial_port_write_packet(int serline, char *buffer, int length);

unsigned xserial_set_baudrate (unsigned baudrate);
unsigned xserial_set_baud     (const char *baud);
void     xserial_set_device   (const char *device);

/* Socket routines. */
int            xsocket_port_open    ();
void           xsocket_set_port     (const char *port);
unsigned       xsocket_get_port     ();
void           xsocket_set_server   (const char *server);
const char *   xsocket_get_server   ();

#endif  /* __SENSORS_H__ */



