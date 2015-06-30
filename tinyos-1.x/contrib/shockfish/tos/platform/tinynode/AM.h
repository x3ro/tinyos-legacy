/* 
 * Copyright (c) 2005, Ecole Polytechnique Federale de Lausanne (EPFL)
 * and Shockfish SA, Switzerland.
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * - Redistributions of source code must retain the above copyright notice,
 *   this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the distribution.
 * - Neither the name of the Ecole Polytechnique Federale de Lausanne (EPFL) 
 *   and Shockfish SA, nor the names of its contributors may be used to 
 *   endorse or promote products derived from this software without 
 *   specific prior written permission.
 * 
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
 * TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA,
 * OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE
 * USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * ========================================================================
 */

/*
 * Message format for tinynode platform.
 *
 */

#ifndef AM_H_INCLUDED
#define AM_H_INCLUDED
enum {
  TOS_BCAST_ADDR = 0xffff,
  TOS_UART_ADDR = 0x007e,
};

#ifndef DEF_TOS_AM_GROUP
#define DEF_TOS_AM_GROUP 0x7d
#endif

enum {
  TOS_DEFAULT_AM_GROUP = DEF_TOS_AM_GROUP
};

uint8_t TOS_AM_GROUP = TOS_DEFAULT_AM_GROUP;

#ifndef TOSH_DATA_LENGTH
#define TOSH_DATA_LENGTH 30
#endif

#ifndef TOSH_AM_LENGTH
#define TOSH_AM_LENGTH 1
#endif

#ifndef TINYSEC_MAC_LENGTH
#define TINYSEC_MAC_LENGTH 4
#endif

#ifndef TINYSEC_IV_LENGTH
#define TINYSEC_IV_LENGTH 4
#endif

#ifndef TINYSEC_ACK_LENGTH
#define TINYSEC_ACK_LENGTH 1
#endif

#if 1
typedef struct TOS_Msg
{
  uint8_t length;
  union {
    uint8_t ack; 
    uint8_t whitening; /* this field should only be used inside the radio driver. 
			  it contains a byte which is XORed with the packet to 'whiten' 
			  it (ie, avoid all-0 or all-1 bursts). */
  };
  uint16_t addr;
  uint8_t type;
  uint8_t group; 
  int8_t data[TOSH_DATA_LENGTH];
  uint16_t crc;

  /* The following fields are not actually transmitted or received 
   * on the radio! They are used for internal accounting only.
   * The reason they are in this structure is that the AM interface
   * requires them to be part of the TOS_Msg that is passed to
   * send/receive operations.
   */
  uint16_t strength;
  uint16_t time;
  uint8_t sendSecurityMode;
  uint8_t receiveSecurityMode;  
} TOS_Msg;

enum {
  TOSH_HEADER_SIZE = offsetof(TOS_Msg, data),
  TOSH_TRAILER_SIZE = sizeof(((struct TOS_Msg *)0)->crc),
  MSG_NONWHITENED_OFFSET = offsetof(TOS_Msg, addr)
};

#else
typedef struct TOS_Msg
{
  /* The following fields are transmitted/received on the radio. */
  uint16_t addr;
  uint8_t type;
  uint8_t group;
  uint8_t dummy;
  uint8_t length;
  int8_t data[TOSH_DATA_LENGTH];
  uint16_t crc;

  /* The following fields are not actually transmitted or received 
   * on the radio! They are used for internal accounting only.
   * The reason they are in this structure is that the AM interface
   * requires them to be part of the TOS_Msg that is passed to
   * send/receive operations.
   */
  uint16_t strength;
  uint8_t ack;
  uint16_t time;
  uint8_t sendSecurityMode;
  uint8_t receiveSecurityMode;  
} TOS_Msg;
#endif


typedef struct TOS_Msg_TinySecCompat
{
  /* The following fields are transmitted/received on the radio. */
  uint16_t addr;
  uint8_t type;
  // length, group and dummy bytes are rotated
  uint8_t length;
  uint8_t group;
  uint8_t dummy;
  int8_t data[TOSH_DATA_LENGTH];
  uint16_t crc;

  /* The following fields are not actually transmitted or received 
   * on the radio! They are used for internal accounting only.
   * The reason they are in this structure is that the AM interface
   * requires them to be part of the TOS_Msg that is passed to
   * send/receive operations.
   */
  uint16_t strength;
  uint8_t ack;
  uint16_t time;
  uint8_t sendSecurityMode;
  uint8_t receiveSecurityMode;  
} TOS_Msg_TinySecCompat;

typedef struct TinySec_Msg
{ 
  uint16_t addr;
  uint8_t type;
  uint8_t length;
  // encryption iv
  uint8_t iv[TINYSEC_IV_LENGTH];
  // encrypted data
  uint8_t enc[TOSH_DATA_LENGTH];
  // message authentication code
  uint8_t mac[TINYSEC_MAC_LENGTH];

  // not transmitted - used only by MHSRTinySec
  uint8_t calc_mac[TINYSEC_MAC_LENGTH];
  uint8_t ack_byte;
  bool cryptoDone;
  bool receiveDone;
  // indicates whether the calc_mac field has been computed
  bool MACcomputed;
} __attribute__((packed)) TinySec_Msg;



enum {
  MSG_DATA_SIZE = offsetof(struct TOS_Msg, crc) + sizeof(uint16_t), // 36 by default
  TINYSEC_MSG_DATA_SIZE = offsetof(struct TinySec_Msg, mac) + TINYSEC_MAC_LENGTH, // 41 by default
  DATA_LENGTH = TOSH_DATA_LENGTH,
  LENGTH_BYTE_NUMBER = offsetof(struct TOS_Msg, length) + 1,
  TINYSEC_NODE_ID_SIZE = sizeof(uint16_t)
};

enum {
  TINYSEC_AUTH_ONLY = 1,
  TINYSEC_ENCRYPT_AND_AUTH = 2,
  TINYSEC_DISABLED = 3,
  TINYSEC_RECEIVE_AUTHENTICATED = 4,
  TINYSEC_RECEIVE_CRC = 5,
  TINYSEC_RECEIVE_ANY = 6,
  TINYSEC_ENABLED_BIT = 128,
  TINYSEC_ENCRYPT_ENABLED_BIT = 64
} __attribute__((packed));


typedef TOS_Msg *TOS_MsgPtr;

uint8_t TOS_MsgLength(uint8_t type)
{
#if 0
  uint8_t i;

  for (i = 0; i < MSGLEN_TABLE_SIZE; i++)
    if (msgTable[i].handler == type)
      return msgTable[i].length;
#endif

  return offsetof(TOS_Msg, strength);
}
#endif
