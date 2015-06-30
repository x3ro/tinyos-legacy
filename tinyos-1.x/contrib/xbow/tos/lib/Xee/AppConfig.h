// Central include file for reading and writing permanent parameters.
//
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
#ifndef AppConfigHedit
#define AppConfigHedit 1
//
// Modification History:
//  23Jan04 MJNewman 1: Created.


// Data structure declarations for permanent parameters.
#include "config.h"

// System definitions of eeprom read and write routines must be
// included here or the routines end up as undefined globals. The
// routines are actually not uset in AppConfig, but in InternalEEPROM
// when that is wired in.
#include <avr/eeprom.h> 

enum {
  AM_CMD_SET_CONFIG = 0x30,
  AM_CMD_GET_CONFIG,
  AM_CMD_DATA_CONFIG,
  //AM_CMD_SET_RADIO,
  //AM_CMD_GET_RADIO
};

#endif // AppConfigHedit
