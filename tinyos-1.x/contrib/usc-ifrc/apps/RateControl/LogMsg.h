/*
 * "Copyright (c) 2000-2005 The Regents of the University of Southern California.  
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF SOUTHERN CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY OF
 * SOUTHERN CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF SOUTHERN CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF SOUTHERN CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 *
 */

/*
 * Authors: Sumit Rangwala
 * Embedded Networks Laboratory, University of Southern California
 */

#ifndef LOGMSG_H
#define LOGMSG_H

#if defined(LOG_RLOCAL) || defined (LOG_NEIGH)  || defined(LOG_LQI) || defined (LOG_PACKLOSS) || defined (LOG_LATENCY) || defined (LOG_TPUT) || defined (LOG_TRANS) || defined(LOG_LINKLOSS) || defined(LOG_QUEUE)

/* A Log msg consist of 
 *     - type 
 *     - size 
 *     - a union of 9 different kind of structure.
 * For any kind of log we typecast TOSMsg.data to logPacket
 * and then set up the appropriate field and send the
 * packet.
 */

/* logPacket.type and logPacket.size forms the header */
#define LOGHEADER 2 


/* Type value for various kinds of log */
enum { 
    RLOCAL = 0, // rLocal value of the current node 
    NEIGHINFO = 1, 
    LQI = 2, 
    PACKLOSS = 3,
    THROUGHPUT = 4,
    PACKINS = 5,
    TRANS = 6,
    LINKLOSSRATE = 7,
    QUEUEINFO = 8,
    SDLOSS = 9,
    OTHER = 10,
};

enum {
    QUEUEFULL = 0,
    LINKLOSS,
};

typedef struct _rlocal {
    uint32_t rLocal;
    uint32_t rThreshold;
    uint32_t ssThresh;
    uint32_t increment;
}RLocal;

typedef struct _neigh {
    uint16_t neighId;
    uint8_t  type;
    uint8_t  mode;
    uint32_t rNeigh;
}Neigh;

typedef struct _link {
    uint16_t nodeId;
    uint8_t lqi;
}Link;

typedef struct _packLoss{ 
    uint16_t originId;
    uint16_t seqNo;
    uint8_t qSize;
    uint8_t cause;
}PackLoss;

typedef struct _tput { 
    uint16_t nodeId;
    uint16_t seqNo;
    uint32_t mCount;
}Tput;

/* For PACKINS */
enum {
    SEND = 0,
    RECEIVE,
};

typedef struct _packIns {
    uint16_t nodeId;
    uint16_t seqNo;
    bool     status; // Sent or Received
}PackIns;

// tells how many time a packet was transmitted 
// at the current node
typedef struct _transInfo{
    uint16_t originId;
    uint16_t seqNo; 
    uint8_t  xmitCount;
    bool     drop;
}TransInfo;


typedef struct _linkQuality {
    uint16_t nodeId;
    uint16_t packetLoss;
    uint16_t packetCount;
}LinkQuality;

typedef struct _queue {
    uint8_t avgLength;
    uint8_t instLength;
    uint8_t enqueue;
    uint8_t dequeue;
    uint8_t fQueueIdle;
    uint8_t taskPending;
}Queue;


typedef struct _logPacket { 
    uint8_t type;
    uint8_t size;
    union {
        RLocal rLocal[(DATA_LENGTH - LOGHEADER)/sizeof(RLocal)];
        Link link[(DATA_LENGTH - LOGHEADER)/sizeof(Link)];
        Neigh neigh[(DATA_LENGTH - LOGHEADER)/sizeof(Neigh)];
        PackLoss packLoss[(DATA_LENGTH - LOGHEADER)/sizeof(PackLoss)];
        Tput throughput[(DATA_LENGTH - LOGHEADER)/sizeof(Tput)];
        PackIns packIns;
        TransInfo tInfo[(DATA_LENGTH - LOGHEADER)/sizeof(TransInfo)];
        LinkQuality linkLoss[(DATA_LENGTH - LOGHEADER)/sizeof(LinkQuality)];
        Queue  qInfo[(DATA_LENGTH - LOGHEADER)/sizeof(Queue)];
    } info;
}logPacket;

#endif 

#endif 

/* #vim: set ts=4 tw=60: */
