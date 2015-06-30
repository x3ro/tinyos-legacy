// Copyright (c) 2004 by Sensicast, Inc.
// All rights including that of resale granted to Crossbow, Inc.
//
// Permission to use, copy, modify, and distribute this software and its
// documentation for any purpose, without fee, and without written
// agreement is hereby granted, provided that the above copyright
// notice, the (updated) modification history and the author appear in
// all copies of this source code.
//
// Permission is also granted to distribute this software under the
// standard BSD license as contained in the TinyOS distribution.
//
// @Author: Michael Newman
//
// $Id: MyApp.h,v 1.1 2004/10/11 01:45:50 husq Exp $
//
#define myappHedit 1
//
// Modification History:
//  13Jan04 MJNewman 1: Created.

#include "config.h"

// These are parameter IDs for three test parameters of this application
enum {
  CONFIG_MY_PARAM1 = APP_PARAM_ID(TOS_TEST_APPLICATION,3),
  CONFIG_MY_PARAM2 = APP_PARAM_ID(TOS_TEST_APPLICATION,4),
  CONFIG_MY_PARAM3 = APP_PARAM_ID(TOS_TEST_APPLICATION,5),
};

// Moved to config.h:
/*
typedef struct sysParams{
	uint16_t mote_id;
    uint8_t group_id;
    uint8_t model_type;
    uint8_t submodel_type;
    uint8_t cpu_type;
    uint16_t mote_vendor;
    uint32_t mote_serial;
    uint32_t cpuosc_hz; // 7.3728MHz
    uint8_t radio_type;
} sysCommand;

typedef struct cc1kParams{
    uint32_t cc1k_tuneHZ;
    uint32_t cc1k_lowerHZ;
    uint32_t cc1k_upperHZ;
} cc1kCommand;

typedef struct xbowParams{
    char xbow_facInfo[16];    
} xbowCommand;

// Encodes parameter config readings into the data payload of a TOS message.
typedef struct {
    uint8_t  packet_id; // 0=TOS_SYSTEM
    uint8_t  subPacket_id;
    uint8_t  data[26];
    uint8_t  reserved;
} XbowParamConfigPacket;
*/
