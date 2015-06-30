/*
 * Copyright (c) 2007
 *	The President and Fellows of Harvard College.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 * 3. Neither the name of the University nor the names of its contributors
 *    may be used to endorse or promote products derived from this software
 *    without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE UNIVERSITY AND CONTRIBUTORS ``AS IS'' AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED.  IN NO EVENT SHALL THE UNIVERSITY OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 * OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 */

#include "AM.h"
#include "EruptionDetector.h"

enum {
  AM_CMDMSG = 22,
  AM_REPLYMSG = 23,
  AM_FETCHREPLYMSG = 24,
};

/************************************************************************
 * Command messages
 ************************************************************************/

enum {
  COMMAND_NOP = 0,
  COMMAND_PING = 1,
  COMMAND_FETCH = 2,
  COMMAND_SETPARENT = 3,
  COMMAND_RELEASEPARENT = 4,
  COMMAND_TRIGGERERUPTION = 5,
  COMMAND_SAMPLING = 6,
  COMMAND_SETCHANPARAMS = 7,
  COMMAND_EWMAPARAMS = 8,
  COMMAND_SETGAIN = 9,
  COMMAND_REBOOT = 10,
  COMMAND_LEDS = 11,
};

#ifndef HEARTBEAT_PERIOD
#define HEARTBEAT_PERIOD 10000L
#endif

typedef struct {
  uint32_t block_id;
  uint32_t bitmask; // Bitmask of needed segments in the block
} FetchCmd;

typedef struct {
  uint16_t parent_addr;
} SetParentCmd;

typedef struct {
  uint32_t delay;
} TriggerEruptionCmd;

typedef struct {
  uint32_t timeToReboot;
} RebootCommand;

typedef struct {
  uint16_t enableLeds;
} LedsCommand;

#define MAX_CHANNELS 4
typedef struct {
  uint16_t numChannels;
  uint8_t channels[MAX_CHANNELS];
  uint16_t samplingRate; // Set to 0 to disable sampling on all channels
  uint16_t sampleContinuously;
  uint16_t continuousChannelBitmap;
  uint16_t continuousDownsampleFactor;
  uint16_t gain; // Gain for ALL CHANNELS
} SamplingCmd;

#if 0
typedef struct {
  // If non-zero do calibration rather than setting gain
  uint16_t doCalibration; 
  uint16_t channel;
  uint16_t gain;
} GainCmd;
#endif

typedef struct {
  uint16_t chanID;
  uint16_t algType;
  uint32_t param1;
  uint32_t param2;
  uint32_t param3;
} ChanParams;

typedef struct {
  uint16_t chanID;
  uint16_t enable;
  uint16_t gain_high;
  uint16_t gain_low;
  uint16_t ratio_thresh;
} EWMAParamsCmd;

typedef struct CmdMsg {
  uint16_t destaddr;
  uint16_t type;
  union {
    FetchCmd fetch;
    SetParentCmd setparent;
    TriggerEruptionCmd triggerEruption;
    SamplingCmd sampling;
    ChanParams chanParams;
    EWMAParamsCmd ewmaParams;
    RebootCommand rebootCommand;
    LedsCommand ledsCommand;
  } data;
} CmdMsg;


/************************************************************************
 * Reply messages
 ************************************************************************/

enum {
  REPLY_STATUS = 0,
  REPLY_SETPARENT = 1,
  REPLY_RELEASEPARENT = 2,
  REPLY_SAMPLING = 4,
  REPLY_SETGAIN = 5,
};

#define STATUS_FTSP_SYNCED 0x01

typedef struct {
  uint16_t swversion; // Software version number
  uint16_t status;    // Status word bits defined above
  uint32_t localTime; // In units returned by 'GlobalTime' interface
  uint32_t globalTime; // In units returned by 'GlobalTime' interface
  uint16_t parent_addr;
  uint16_t parent_quality;
  uint16_t depth;
  // KLDEBUG - the uint32_t should be changed to blocksqnnbr_t
  uint32_t tailBlockID;    // inclusive
  uint32_t headBlockID;    // exclusive!!!
  uint16_t dataStoreQueueSize;
  // 11 Jun 2005 : GWA : Now collecting some info about the sampling
  //               component's performance.
  uint32_t missedSamples;
  uint32_t badSamples;
  uint32_t collectedSamples;
  uint16_t voltage;
  uint16_t temperature;
  uint16_t eruptionCount;
  uint16_t ledState;
} StatusReply;

typedef struct {
  uint16_t success; // If non-zero indicates success
} SuccessReply;

struct ReplyMsg {
  uint16_t originaddr;
  uint16_t type;
  union {
    StatusReply status;
    SuccessReply success;
  } data;
};
typedef struct ReplyMsg ReplyMsg;

/************************************************************************
 * Fetch reply message
 ************************************************************************/

#define FETCH_BLOCK_SIZE STM25P_PAGE_SIZE
#define FETCH_SEGMENT_SIZE 32
#define FETCH_BITMASK_LENGTH (FETCH_BLOCK_SIZE / FETCH_SEGMENT_SIZE)

struct FetchReplyMsg {
  // originaddr is Needed by the java GUI.
  uint16_t originaddr;  
  uint32_t block_id;
  uint16_t offset;
  uint8_t data[FETCH_SEGMENT_SIZE];
}; 
//__attribute__ ((packed));
typedef struct FetchReplyMsg FetchReplyMsg;



