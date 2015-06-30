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

#ifndef DRIVERMSGS_H
#define DRIVERMSGS_H

enum {
    AM_REQUESTMSG = 22,
    AM_REPLYMSG = 23,
};


/************************************************************************
 * Request messages
 ************************************************************************/

enum {
    REQUESTMSG_TYPE_STATUS = 1,
    REQUESTMSG_TYPE_STARTSAMPLING = 2,
    REQUESTMSG_TYPE_STOPSAMPLING = 3,
    REQUESTMSG_TYPE_RESETDATASTORE = 4,
};

typedef struct {
    uint16_t numChannels;
    uint16_t samplingRate; // Set to 0 to disable sampling on all channels
} SamplingCmd;

typedef struct RequestMsg {
    uint16_t srcAddr;
    uint16_t type;
    union {
        SamplingCmd sampling;
    } data;
} RequestMsg;




/************************************************************************
 * Reply messages
 ************************************************************************/

enum {
    REPLYMSG_TYPE_STATUS = 10,
};


#ifndef HEARTBEAT_PERIOD
#define HEARTBEAT_PERIOD 4000L
#endif


// Bitfields for systemStatus
enum {
    SYSTEM_STATUS_BIT_ISSAMPLING = 1,
    SYSTEM_STATUS_BIT_ISTIMESYNCED = 2,
};

typedef struct {
    uint16_t systemStatus;  // Status word bits defined above
    uint32_t localTime;     // In units returned by 'GlobalTime' interface
    uint32_t globalTime;    // In units returned by 'GlobalTime' interface

    uint32_t tailBlockID;   // inclusive
    uint32_t headBlockID;   // exclusive!!!
    uint16_t dataStoreQueueSize;
} StatusReply;

/* typedef struct { */
/*     uint16_t success; // If non-zero indicates success */
/* } SuccessReply; */

typedef struct ReplyMsg {
    uint16_t srcAddr;
    uint16_t type;
    union {
        StatusReply status;
//        SuccessReply success;
    } data;
} ReplyMsg;


#endif
