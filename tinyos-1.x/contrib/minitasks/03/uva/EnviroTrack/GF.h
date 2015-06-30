/* "Copyright (c) 2000-2002 University of Virginia.  
 * All rights reserved.
 * 
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF VIRGINIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY OF
 * VIRGINIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF VIRGINIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF VIRGINIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 * 
 * Authors: Gary Zhou,Tian He 
 */

#ifndef _H_GF_h
#define _H_GF_h

#include "SystemParameters.h"

enum{
    
    RADIO_RANGE     = 2,//it is used to set the range of neighbors.
    
    PAYLOAD_SIZE = 18,
	MAX_NEIGHBOR = 25,

    MAX_BC_BUFFER= 5,
    
    AM_GF_DATA_MSG   = 3,
    AM_GF_BEACON_MSG = 4,
    AM_BC_DATA_MSG   = 5,
    
    // value in second
	FIRST_BEACON_TIME  = 10,
    SEND_BEACON_PERIOD = 20,
	REFRESH_NT_PERIOD  = 200,
};

typedef char PAYLOAD[PAYLOAD_SIZE];

typedef struct{
	uint16_t x;
	uint16_t y;
}POSITION;

typedef struct{
	uint16_t globalSenderID;
	uint16_t globalReceiverID;
	POSITION position;
    uint8_t seqNO;
	uint8_t appID;
} GF_HEADER;


typedef struct{
	GF_HEADER header;
	PAYLOAD data;
} GF_PACKET;

typedef struct{
	uint16_t globalSenderID;
	uint16_t globalReceiverID;
    uint16_t seqNO;
	char  hopCountLimit;
    char  hopCount;
	uint8_t appID;
} BC_HEADER;


typedef struct{
	BC_HEADER header;
	PAYLOAD data;
} BC_PACKET;

typedef struct{
    uint16_t globalSenderID[MAX_BC_BUFFER];
    uint16_t seqNO[MAX_BC_BUFFER];
    uint16_t head;
} BC_BUFFER;

typedef struct{
	uint16_t       NeighborID[MAX_NEIGHBOR];
    POSITION    NeighborPOSITION [MAX_NEIGHBOR];
	uint16_t       NeighborStatus[MAX_NEIGHBOR];
	uint16_t       RefreshStatus[MAX_NEIGHBOR];
	uint16_t       size;
} NEIGHBOR_TABLE;

typedef struct{
	uint16_t globalSenderID;
	POSITION position;
}BEACON;


#endif //_H_GF_h

