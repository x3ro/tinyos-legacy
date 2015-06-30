// Example of servicing save and restore of parameters using general
// interface: Config
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
#define MessageConfigEdit 1
//
// Modification History:
//  13Jan04 MJNewman 1: Created.
//

module MyAppComplex {
    provides interface StdControl;

    provides interface Config as MySetting;
}
implementation {

#ifndef MIN
#define MIN(_a,_b) ((_a < _b) ? _a : _b)
#endif

    command result_t StdControl.init()
    {
	return SUCCESS;
    }

    command result_t StdControl.start()
    {
	return SUCCESS;
    }

    command result_t StdControl.stop()
    {
	return SUCCESS;
    }

    int32_t appVariable32 = 23; // default value

    command size_t MySetting.get(void *buffer, size_t size) {
	if (buffer != NULL) {
	    memcpy(buffer,&appVariable32, MIN(size,sizeof(appVariable32)));
	};
	return sizeof(appVariable32);
    }

    command result_t MySetting.set(void *buffer, size_t size) {
	int16_t value;

	if (size != sizeof appVariable32)
	    return FAIL;

	value = *(int32_t *)buffer;
	if (value <= 100) // a sample consistency check
	{
	    appVariable32 = value;
	    return SUCCESS;
	}
	// Or should this return SUCCESS and post a signal-fail task?
	return FAIL;
    }
}

