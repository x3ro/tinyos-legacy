/**
 * Handles parsing of xsensor packets.
 *
 * @file      xpacket.h
 * @author    Martin Turon
 * @version   2004/2/18    mturon      Initial version
 *
 * Copyright (c) 2004-2005 Crossbow Technology, Inc.   All rights reserved.
 * 
 * $Id: xpacket.h,v 1.2 2005/02/22 20:14:07 mturon Exp $
 */

typedef struct TosMsg
{
  uint16_t addr;
  uint8_t  am_type;
  uint8_t  group;
  uint8_t  length;
} __attribute__ ((packed)) TosMsg;

typedef struct MultihopMsg
{
  uint16_t destaddr;
  uint16_t nodeid;
  int16_t  seqno;
  uint8_t  hops;
} __attribute__ ((packed)) MultihopMsg;
