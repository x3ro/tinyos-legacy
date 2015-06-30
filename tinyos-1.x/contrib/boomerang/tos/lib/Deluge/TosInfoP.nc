/*
 * Copyright (c) 2006 Moteiv Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached MOTEIV-LICENSE     
 * file. If you do not find these files, copies can be found at
 * http://www.moteiv.com/MOTEIV-LICENSE.txt and by emailing info@moteiv.com.
 */
#include "NetProg.h"

/**
 * Stores TinyOS node information (like TOS_LOCAL_ADDRESS) to internal flash
 */
module TosInfoP {
  provides interface Init;
  provides command void writeTosInfo();
  uses interface InternalFlash as IFlash;
  uses interface Crc;
}
implementation {

  uint16_t computeTosInfoCrc(NetProg_TOSInfo* tosInfo) {
    return call Crc.crc16(tosInfo, sizeof(NetProg_TOSInfo)-2);
  }

  command void writeTosInfo() {
    NetProg_TOSInfo tosInfo;
    uint16_t crc;
    call IFlash.read((uint8_t*)IFLASH_TOS_INFO_ADDR, &tosInfo, sizeof(tosInfo));
    tosInfo.addr = TOS_LOCAL_ADDRESS;
    tosInfo.groupId = TOS_AM_GROUP;
    crc = computeTosInfoCrc(&tosInfo);
    // don't write if data is already correct
    if (tosInfo.crc == crc)
      return;
    tosInfo.crc = crc;
    call IFlash.write((uint8_t*)IFLASH_TOS_INFO_ADDR, &tosInfo, sizeof(tosInfo));
  }

  command result_t Init.init() {

#ifndef PLATFORM_PC
    NetProg_TOSInfo tosInfo;

    call IFlash.read((uint8_t*)IFLASH_TOS_INFO_ADDR, &tosInfo, sizeof(tosInfo));

    if (tosInfo.crc == computeTosInfoCrc(&tosInfo)) {
      TOS_AM_GROUP = tosInfo.groupId;
      atomic TOS_LOCAL_ADDRESS = tosInfo.addr;
    }
    else {
      call writeTosInfo();
    }
#endif

    return SUCCESS;
  }
}

