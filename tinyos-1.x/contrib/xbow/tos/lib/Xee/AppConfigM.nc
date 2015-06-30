// The point of this file is essentially to implement Config over either
//   ConfigInt16, ConfigInt8 or Config (only one should of those two should be wired).
//
//   When abstract components come along, the names unique to data
//   types can go away.
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
#define AppConfigMedit 1
//
// Modification History:
//  13Jan04 MJNewman 1: Created.


includes config;

module AppConfigM {
    // The interface controllers (setting via radio, from eeprom) use to
    // access configuration variables
    provides interface Config as ExternalConfig[AppParamID_t setting];

    uses interface Config[AppParamID_t setting];
    uses interface ConfigInt8[AppParamID_t setting];
    uses interface ConfigInt16[AppParamID_t setting];
}
implementation {
#include <string.h>

#ifndef MIN
#define MIN(_a,_b) ((_a < _b) ? _a : _b)
#endif

    // retain value of parameter ID for tasks that signal the results
    AppParamID_t setParmID;
    AppParamID_t getParmID;

    command result_t ExternalConfig.set[AppParamID_t id](void *buffer, size_t size) {
	return call Config.set[id](buffer, size);
    }

    default command result_t Config.set[AppParamID_t id](void *buffer, size_t size) {
	int16_t value;

	if ((size != sizeof(int16_t)) && (size != sizeof(int8_t))) {
	    return FAIL;
	};
	// Config failed, assume it was because it was not wired and
	// try ConfigInt16 and ConfigInt8 (only one of the three should be wired anyway)
	value = 0;
	memcpy(&value, buffer, MIN(size,sizeof(value)));
	if (call ConfigInt16.set[id](value)) {
	    setParmID = id;
	    return SUCCESS;
	};
	if (call ConfigInt8.set[id](value)) {
	    setParmID = id;
	    return SUCCESS;
	};
	return FAIL;
    }

    default command result_t ConfigInt8.set[AppParamID_t id](int8_t value) {
	return FAIL;
    }

    default command result_t ConfigInt16.set[AppParamID_t id](int16_t value) {
	return FAIL;
    }

    command size_t ExternalConfig.get[AppParamID_t id](void *buffer, size_t available) {
	return call Config.get[id](buffer, available);
    }

    default command size_t Config.get[AppParamID_t id](void *buffer, size_t size) {
	int16_t value;
	// Config failed, assume it was because it was not wired and
	// try ConfigInt16 or ConfigInt8 (only one of the three should be wired anyway)
	getParmID = TOS_NO_PARAMETER; // Detect unconnected ConfigIntXX
	value = call ConfigInt16.get[id]();
	if (getParmID != TOS_UNUSED_PARAMETER) {
	    memcpy(buffer, &value, sizeof(int16_t));
	    getParmID = id;
	    return sizeof(int16_t);
	};	
	getParmID = TOS_NO_PARAMETER; // Detect unconnected ConfigIntXX
	value = call ConfigInt8.get[id]();
	if (getParmID != TOS_UNUSED_PARAMETER) {
	    memcpy(buffer, &value, sizeof(int8_t));
	    getParmID = id;
	    return sizeof(int8_t);
	};	
	return 0;
    }

    default command int16_t ConfigInt16.get[AppParamID_t id]() {
	getParmID = TOS_UNUSED_PARAMETER;
	return 0;
    }

    default command int8_t ConfigInt8.get[AppParamID_t id]() {
	getParmID = TOS_UNUSED_PARAMETER;
	return 0;
    }
}
