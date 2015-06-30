// This is a simplified and type-specialised (16 bit int) config interface
// suitable for most uses. Use Config if you need the split-phase behaviour,
// or the ability to recoginze failure of a get.
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
#define ConfigInt16Edit 1
//
// Modification History:
//  13Jan04 MJNewman 1: Created.


interface ConfigInt16
{
  command int16_t get();
  command result_t set(int16_t value);
}
