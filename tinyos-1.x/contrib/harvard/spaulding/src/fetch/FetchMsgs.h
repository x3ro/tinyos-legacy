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

#ifndef FETCHMSGS_H
#define FETCHMSGS_H
//#include "Storage.h"

// *******************************************************************
// * Request
// *******************************************************************

enum {
    AM_FETCHREQUESTMSG = 101,
    AM_FETCHREPLYMSG = 102,
};

typedef struct FetchRequestMsg {
    uint16_t srcAddr;
    uint32_t blockID;
    uint32_t bitmask; // Bitmask of needed segments in the block
} FetchRequestMsg;



// *******************************************************************
// * Reply
// *******************************************************************

enum {
    FETCH_BLOCK_SIZE = 256,   //STM25P_PAGE_SIZE,
    FETCH_SEGMENT_SIZE = 64L, // DO NOT change without making sure TOSH_DATA_LENGTH is big enough
    FETCH_BITMASK_LENGTH = (FETCH_BLOCK_SIZE / FETCH_SEGMENT_SIZE),
};    

typedef struct FetchReplyMsg {
    // originaddr is Needed by the java GUI.
    uint16_t originaddr;  
    uint32_t block_id;
    uint16_t offset;
    uint8_t  data[FETCH_SEGMENT_SIZE];
} FetchReplyMsg; 


#endif
