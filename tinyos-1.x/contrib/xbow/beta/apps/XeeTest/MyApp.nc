// Example of servicing save and restore of parameters using type specific
// interface: ConfigInt16
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

module MyApp {
  provides interface StdControl;

  provides interface ConfigInt16 as MySetting16;
  provides interface ConfigInt8 as MySetting8;
}
implementation {

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

  int16_t appVariable16 = 22; // default value

  command int16_t MySetting16.get() {
    return appVariable16;
  }

  command result_t MySetting16.set(int16_t value) {
    if (value <= 100) // a sample consistency check
      {
	appVariable16 = value;
	return SUCCESS;
      }
    else
      return FAIL;
  }


  int8_t appVariable8 = 13; // default value

  command int8_t MySetting8.get() {
      return appVariable8;
  }

  command result_t MySetting8.set(int8_t value) {
      if (value <= 50) // a sample consistency check
      {
	  appVariable8 = value;
	  return SUCCESS;
      }
      else
	  return FAIL;
  }

}
