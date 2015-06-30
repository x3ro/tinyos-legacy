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

/**
 * Description - defines the DataStore variables and constants
 *
 * @author: Konrad Lorincz
 * @version 1.0 - 4/20/05
 */
#ifndef DATASTORESTM25P_H
#define DATASTORESTM25P_H
#include "Storage.h"
#include "Block.h"

typedef uint16_t  blockindex_t;
typedef uint32_t  blockaddr_t;   // 32-bit


// ------- originally in Block.h -----------
typedef struct BlockHandle {
    volume_t      volumeIndex;
    blockindex_t  blockIndex;
    blocksqnnbr_t blockSqnNbr;    
} BlockHandle;

// --------------------------- BlockHandle -------------------------------
/**
 * Initializes a block to a default value.
 */
inline void BlockHandle_init(BlockHandle *blockHandlePtr)
{      
    blockHandlePtr->volumeIndex = 0;
    blockHandlePtr->blockIndex = 0;
    blockHandlePtr->blockSqnNbr = 0;
}

/**
 * Prints the content of a block.
 */
inline void BlockHandle_print(BlockHandle *bhPtr)
{
  #ifdef PRINTFUART_ENABLED
    printfUART("----- BlockHandle_print() - for BlockHanle %p ----- \n", bhPtr);
    printfUART("    <volumeIndex= %u, blockIndex= %u, blockSqnNbr= %lu\n", 
               bhPtr->volumeIndex, bhPtr->blockIndex, bhPtr->blockSqnNbr);
    printfUART("------------------------------------------------\n");
  #endif
}

// ------- originally in Block.h -----------


#ifndef DS_NBR_VOLUMES
#define DS_NBR_VOLUMES 13    // by default, Deluge uses 3 volumes
#endif

#ifndef DS_NBR_BLOCKS_PER_VOLUME
#define DS_NBR_BLOCKS_PER_VOLUME  ((blockindex_t) ((blockaddr_t)STORAGE_BLOCK_SIZE / sizeof(Block)) )
#endif

enum {
    DS_NBR_BLOCKS  = (blockindex_t) DS_NBR_VOLUMES * DS_NBR_BLOCKS_PER_VOLUME,
};

enum {
    DS_PARAM_VOLUME_ID_0 = unique("StorageManager"),
    DS_PARAM_VOLUME_ID_1 = unique("StorageManager"),
    DS_PARAM_VOLUME_ID_2 = unique("StorageManager"),
    DS_PARAM_VOLUME_ID_3 = unique("StorageManager"),
    DS_PARAM_VOLUME_ID_4 = unique("StorageManager"),
    DS_PARAM_VOLUME_ID_5 = unique("StorageManager"),
    DS_PARAM_VOLUME_ID_6 = unique("StorageManager"),
    DS_PARAM_VOLUME_ID_7 = unique("StorageManager"),
    DS_PARAM_VOLUME_ID_8 = unique("StorageManager"),
    DS_PARAM_VOLUME_ID_9 = unique("StorageManager"),
    DS_PARAM_VOLUME_ID_10 = unique("StorageManager"),
    DS_PARAM_VOLUME_ID_11 = unique("StorageManager"),
    DS_PARAM_VOLUME_ID_12 = unique("StorageManager"),
#if DS_NBR_VOLUMES >= 14
    DS_PARAM_VOLUME_ID_13 = unique("StorageManager"),
#if DS_NBR_VOLUMES >= 15
    DS_PARAM_VOLUME_ID_14 = unique("StorageManager"),
#if DS_NBR_VOLUMES >= 16
    DS_PARAM_VOLUME_ID_15 = unique("StorageManager"),
#endif
#endif
#endif
};

struct datastorevolume_t {
    volume_t    parID;  // the parameterized interface volumeID
    volume_id_t volID;  // the actual volumeID
};

static const struct datastorevolume_t DS_VOLS[DS_NBR_VOLUMES] = {
    { DS_PARAM_VOLUME_ID_0, 0 },
    { DS_PARAM_VOLUME_ID_1, 1 },
    { DS_PARAM_VOLUME_ID_2, 2 },
    { DS_PARAM_VOLUME_ID_3, 3 },
    { DS_PARAM_VOLUME_ID_4, 4 },
    { DS_PARAM_VOLUME_ID_5, 5 },
    { DS_PARAM_VOLUME_ID_6, 6 },
    { DS_PARAM_VOLUME_ID_7, 7 },
    { DS_PARAM_VOLUME_ID_8, 8 },
    { DS_PARAM_VOLUME_ID_9, 9 },
    { DS_PARAM_VOLUME_ID_10, 10 },
    { DS_PARAM_VOLUME_ID_11, 11 },
    { DS_PARAM_VOLUME_ID_12, 12 },
#if DS_NBR_VOLUMES >= 14
    { DS_PARAM_VOLUME_ID_13, 13 },
#if DS_NBR_VOLUMES >= 15
    { DS_PARAM_VOLUME_ID_14, 14 },
#if DS_NBR_VOLUMES >= 16
    { DS_PARAM_VOLUME_ID_15, 15 },
#endif
#endif
#endif
};

#endif
