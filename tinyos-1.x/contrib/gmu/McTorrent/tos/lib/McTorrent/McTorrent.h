/**
 * Copyright (c) 2006 - George Mason University
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs, and the author attribution appear in all copies of this
 * software.
 *
 * IN NO EVENT SHALL GEORGE MASON UNIVERSITY BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF GEORGE MASON
 * UNIVERSITY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *      
 * GEORGE MASON UNIVERSITY SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND GEORGE MASON UNIVERSITY HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS.
 **/

/**
 * @author Leijun Huang <lhuang2@gmu.edu>
 **/

#ifndef __MCTORRENT_H__
#define __MCTORRENT_H__

// Suppose channel 0 is reserved for common use.
// Since we use uint8_t as data type of channels, the max number cannot exceed 256.
enum {
    MC_CHANNELS = 16,
};

enum {
    BLOCKSTORAGE_ID_0 = unique("StorageManager"),
    BLOCKSTORAGE_VOLUME_ID_0 = 0xDF,
};

enum {
    METADATA_SIZE = 16,
};

typedef struct {
    uint16_t  objId;     // Valid objId starts from 1.
    uint8_t   numPages;
    uint8_t   numPktsLastPage;
    uint8_t   numPagesComplete;
    uint8_t   pad;    // pad must be set 0 when computing crc.
    uint16_t  crcData;  // CRC of object data.
    uint16_t  crcMeta;  // CRC of all above.
} __attribute__((packed)) ObjMetadata;

enum {
    PKTS_PER_PAGE = 24,
    PAGE_BITVEC_SIZE = ((PKTS_PER_PAGE-1)/8 + 1),
    BYTES_PER_PKT = 22,      //TODO: up to 22.
    BYTES_PER_PAGE = (PKTS_PER_PAGE * BYTES_PER_PKT)
};

enum {
    // Times in milliseconds are based on (1 s = 1024 ms).

    // Time needed to transmit one packet, in milliseconds.
    // Value for PC is observed from TOSSIM.
    // Values for hardware platforms are observed from experiments.
#if defined(PLATFORM_PC)
    PKT_TX_TIME               = 34,
#elif defined(PLATFORM_MICA2)
    PKT_TX_TIME               = 32,
#elif defined(PLATFORM_TELOSB)
    PKT_TX_TIME               = 16,
#endif

    INTER_PKT_DELAY           = 16,
    
    RX_GRACE_PERIOD           = 64,

    MIN_ADV_PERIOD_LOG2       = 11,
    MAX_ADV_PERIOD_LOG2       = 21,
    MAX_OVERHEARD_ADVS        = 1,
    NUM_NEWDATA_ADVS_REQUIRED = 2,
    MAX_REQ_DELAY             = 512,
    MAX_RETX_DELAY            = 16,

    NUM_CHN_MSGS              = 2,
};

#endif

