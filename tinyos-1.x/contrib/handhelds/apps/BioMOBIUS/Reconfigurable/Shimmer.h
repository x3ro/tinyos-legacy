 /*
 * Copyright (c) 2007, Intel Corporation
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 * Redistributions of source code must retain the above copyright notice,
 * this list of conditions and the following disclaimer.
 *
 * Redistributions in binary form must reproduce the above copyright notice,
 * this list of conditions and the following disclaimer in the documentation
 * and/or other materials provided with the distribution.
 *
 * Neither the name of the Intel Corporation nor the names of its contributors
 * may be used to endorse or promote products derived from this software
 * without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
 * LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 *
 *  Authors:  Adrian Burns
 *            April, 2007
 *
 *            Michael Fogarty
 *            October, 2007
 *
 * $Author: ayer1 $ 
 * $Date: 2009/09/10 13:02:54 $ 
 * $Revision: 1.1 $
 */

#ifndef SHIMMER_H
#define SHIMMER_H

// single byte commands interpreted by the shimmer
enum {
  SHIMMER_PERSONALITY = 0x01,      // ^a
  SHIMMER_GET_BATTERY = 0x02,      // ^b
  SHIMMER_FETCH = 0x06,            // ^f
  SHIMMER_START = 0x07,            // ^g
  SHIMMER_START_REV2 = 0x08,       // ^h
  // 17 0x11 ^q is used for debug
  SHIMMER_RESET_SECTOR = 0x12,     // ^r
  SHIMMER_SD_TEST = 0x14,          // ^t
  SHIMMER_WRITE_MARKER = 0x17,     // ^w
  SHIMMER_STOP = 0x20,             // <space>
  SHIMMER_LATCH_SEQUENCE = 0x21,   // '!'
  SHIMMER_MULTIPLEXER_ON = 0x7E,   // '~'
  SHIMMER_MULTIPLEXER_OFF = 0x60,  // '`'
  SHIMMER_LOGSD_ON = 0x24,         // '$'
  SHIMMER_LOGSD_OFF = 0x23,        // '#'
  SHIMMER_INCREMENT_SECTOR = 0x2b, // '+'
  SHIMMER_DECREMENT_SECTOR = 0x2d, // '-'
  // channel sequence assignment
  //   0x30..0x3F (0-?) represent adc chan 0..15
  // sample_period =((0x40..0x5A)-0x40) * 10 (@-Z)
  // sample_period+= (0x61..0x69)-0x61       (a-i)
  SHIMMER_ACCEL_RANGE_1_5G = 0x6A, // 'j'
  SHIMMER_ACCEL_RANGE_2_0G = 0x6B, // 'k'
  SHIMMER_ACCEL_RANGE_4_0G = 0x6C, // 'l'
  SHIMMER_ACCEL_RANGE_6_0G = 0x6D, // 'm'
};

enum {
  NUM_ACCEL_CHANS = 3
};

enum {
  NUM_GYRO_CHANS = 3
};

#define NUM_SHIMMER_ADCS 8

enum {
  SHIMMER_REV1 = 0,
  SHIMMER_REV2,
  SHIMMER_SECTOR_TRANSPORT, // decode sample data
  SHIMMER_LOG_TRANSPORT,    // decode first sector of logged data
};

// 32 bit sector num + 2 timestamp words + 253 sample words + 1 crc word
// == 2 + 256 words = 4+512 bytes
#define SHIMMER_SECTOR_TRANSPORT_LENGTH (516) 
#define SHIMMER_PERSONALITY_LENGTH 0x16

// rev1 packet command types
enum {
  PROPRIETARY_DATA_TYPE = 0xFF,
  STRING_DATA_TYPE = 0xFE,
  PERSONALITY_DATA_TYPE = 0xFD,
  COMMAND_RESPONSE_DATA_TYPE = 0xFC,
  PROPRIETARY_DATA_TYPE_ALT_MUX = 0xFB
};

enum {
    // REV2 packet defs -- low overhead packet (LOP).
    // B7, B6 are specified by these two
    // These two specify what goes in b7
    // ------------------------------------ 
    CMD = (0x01 << 7), // 0x80
    DATA = (0x00 << 7), // 0x00
    // if B7 indicates DATA, then data toggle must follow in b6
    // ------------------ 
    // first DATA element after CMD will be DATA0
    DATA0 =(0x00 << 6),
    DATA1 = (0x01 << 6),  // 0x40
};
enum {
    DATA_TOGGLE = DATA1,
    DATA_MASK = 0x3F,   // bottom six bits are data
    // CMD subcommands, b6-b4
    LEGACY = (0x04<<4),  //  REV1 SOF/EOF
    NOT_MUXED = (0x00<<4),
    MUXED = (0x01<<4),
};
enum {
   // if B7 indicates CMD
   // ------------------ 
    REV1_PACKET_SOF = (CMD+LEGACY),      // aka FRAMING_BOF
    REV1_PACKET_EOF = (CMD+LEGACY+0x01), // aka FRAMING_EOF
};

enum {
  SAMPLING_1000HZ = 1,
  SAMPLING_500HZ = 2,
  SAMPLING_250HZ = 4,
  SAMPLING_200HZ = 5,
  SAMPLING_166HZ = 6,
  SAMPLING_125HZ = 8,
  SAMPLING_100HZ = 10,
  SAMPLING_50HZ = 20,
  SAMPLING_10HZ = 100,
  SAMPLING_0HZ_OFF = 255
};

enum {
  FRAMING_SIZE     = 0x4,  // BOF, CRC, CRC, EOF = 4 framing bytes
  FRAMING_CE_COMP  = 0x20,
  FRAMING_CE_CE    = 0x5D,
  FRAMING_CE       = 0x7D,
  FRAMING_BOF      = 0xC0,
  FRAMING_EOF      = 0xC1,
  FRAMING_BOF_CE   = 0xE0,
  FRAMING_EOF_CE   = 0xE1,
};

enum {
   PERS_SAMPLE_MASK = 0x3F,
   PERS_MUX_BIT     = 0x80,
   PERS_REC_BIT     = 0x40
};

#endif // SHIMMER_H
