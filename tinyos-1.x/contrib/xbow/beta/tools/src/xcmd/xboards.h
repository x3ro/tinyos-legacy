/**
 * Global definitions for the command messages of various TinyOS applications.
 *
 * @file      xboards.h
 * @author    Martin Turon
 * @version   2004/10/3    mturon      Initial version
 *
 * Copyright (c) 2004 Crossbow Technology, Inc.   All rights reserved.
 * 
 * $Id: xboards.h,v 1.1 2004/10/07 19:33:13 mturon Exp $
 */

#ifndef __XBOARDS_H__
#define __XBOARDS_H__

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
  XTYPE_XTUTORIAL = 0x88,
} XbowSensorboardType;

#endif
