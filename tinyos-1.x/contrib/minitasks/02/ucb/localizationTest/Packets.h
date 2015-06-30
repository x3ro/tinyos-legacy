/*									tab:4
 *  IMPORTANT: READ BEFORE DOWNLOADING, COPYING, INSTALLING OR USING.  By
 *  downloading, copying, installing or using the software you agree to
 *  this license.  If you do not agree to this license, do not download,
 *  install, copy or use the software.
 *
 *  Intel Open Source License 
 *
 *  Copyright (c) 2002 Intel Corporation 
 *  All rights reserved. 
 *  Redistribution and use in source and binary forms, with or without
 *  modification, are permitted provided that the following conditions are
 *  met:
 * 
 *	Redistributions of source code must retain the above copyright
 *  notice, this list of conditions and the following disclaimer.
 *	Redistributions in binary form must reproduce the above copyright
 *  notice, this list of conditions and the following disclaimer in the
 *  documentation and/or other materials provided with the distribution.
 *      Neither the name of the Intel Corporation nor the names of its
 *  contributors may be used to endorse or promote products derived from
 *  this software without specific prior written permission.
 *  
 *  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 *  ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 *  LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
 *  PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE INTEL OR ITS
 *  CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 *  EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 *  PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 *  PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 *  LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 *  NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 *  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * 
 */
/* 
 * Authors:  Kamin Whitehouse
 *           Intel Research Berkeley Lab
 *           UC Berkeley
 * Date:     8/20/2002
 *
 */


//#include "../../../../../common/common_structs.h"
//#include "../../../../../localization/Localization.h"
//#include "../../../../../ranging/Ranging.h"


#include <Localization.h>
#include <Ranging.h>
#include <NestArch.h>
#include <Command.h>

enum {
  AM_ROUTEBYADDRESS = 100,
  AM_ROUTEBYBROADCAST = 101,
  AM_ROUTEBYLOCATION= 102,
  AM_LOCATIONTUPLE= AM_ROUTEBYBROADCAST,
  AM_RANGINGTUPLE= AM_ROUTEBYBROADCAST,
  AM_ANCHORTUPLE= AM_ROUTEBYBROADCAST,
  AM_ANCHORCORRECTIONTUPLE= AM_ROUTEBYBROADCAST,
  AM_TUPLEREQUESTBYBROADCAST= AM_ROUTEBYBROADCAST,
  AM_TUPLEREQUESTBYADDRESS= AM_ROUTEBYADDRESS
};

typedef struct{
  uint8_t maxHops;
  uint16_t originAddress;
  uint16_t packetNumber;
  uint8_t routingProtocol;
} RouteByBroadcastHeader;

typedef struct{
  uint16_t destinationAddress;
  uint16_t originAddress;
  uint16_t packetNumber;
  uint8_t routingProtocol;
} RouteByAddressHeader;

typedef struct{
  uint16_t destinationX;
  uint16_t destinationY;
  uint16_t destinationAddress;
  uint16_t sourceAddress;
  uint16_t originAddress;
  uint16_t packetNumber;
  uint8_t routingProtocol;  
} RouteByLocationHeader;

struct LocationTuple { 
  location_t location;
  TupleMsgHeader_t tupleInfo;
  RouteByBroadcastHeader routingHeaders;
};

struct RangingTuple { 
  RangingData_t rangingData;
  TupleMsgHeader_t tupleInfo;
  RouteByBroadcastHeader routingHeaders;
};

struct AnchorTuple { 
  anchor_t anchor;
  TupleMsgHeader_t tupleInfo;
  RouteByBroadcastHeader routingHeaders;
};

/*struct AnchorCorrectionTuple { 
  AnchorCorrection_t anchorCorrection;
  TupleMsgHeader_t tupleInfo;
  RouteByBroadcastHeader routingHeaders;
  };*/

struct TupleRequestByBroadcast { 
  struct CommandMsg commandHeaders;
  char commandName[8];
  uint8_t tupleType;
  uint16_t nodeIDofRequestedTuple;
  RouteByBroadcastHeader routingHeaders;
};

struct TupleRequestByAddress { 
  struct CommandMsg commandHeaders;
  char commandName[8];
  uint8_t tupleType;
  uint16_t nodeIDofRequestedTuple;
  RouteByAddressHeader routingHeaders;
};







