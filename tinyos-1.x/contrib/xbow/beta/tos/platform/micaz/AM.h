// $Id: AM.h,v 1.3 2004/06/08 22:41:40 jdprabhu Exp $

/*									tab:4
 * "Copyright (c) 2000-2003 The Regents of the University  of California.  
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY OF
 * CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 *
 * Copyright (c) 2002-2003 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */
/*
 *
 * Authors:		Jason Hill, David Gay, Philip Levis, Chris Karlof
 * Date last modified:  6/25/02
 *
 */

// Message format


/**
 * @author Jason Hill
 * @author David Gay
 * @author Philip Levis
 * @author Chris Karlof
 */
#ifndef AM_H_INCLUDED
#define AM_H_INCLUDED

enum {
  TOS_BCAST_ADDR = 0xffff,
  TOS_UART_ADDR = 0x007e,
};

//#ifndef TOS_BCAST_ADDR
//#define TOS_BCAST_ADDR  0xffff
//#endif
//#define TOS_UART_ADDR   0x007e



#ifndef DEF_TOS_AM_GROUP
#define DEF_TOS_AM_GROUP 0x7d
#endif

enum {
  TOS_DEFAULT_AM_GROUP = DEF_TOS_AM_GROUP
};

uint8_t TOS_AM_GROUP = TOS_DEFAULT_AM_GROUP;

#ifndef TOSH_DATA_LENGTH
#define TOSH_DATA_LENGTH 29
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

typedef struct TOS_Msg
{
#ifdef MICAZOLD
  /* The following fields are transmitted/received on the radio. */
  uint8_t length;
  uint16_t fcf;
  uint8_t dsn;
  uint16_t addr;
  uint8_t type;
  uint8_t group;
  int8_t data[TOSH_DATA_LENGTH];
#endif
  /* The following fields are transmitted/received on the radio. */
  uint8_t length;
  uint8_t fcfhi;
  uint8_t fcflo;
  uint8_t dsn;
  uint16_t destpan;
  uint16_t addr;
  uint8_t type;
  uint8_t group;
  int8_t data[TOSH_DATA_LENGTH];

  /* The following fields are not actually transmitted or received 
   * on the radio! They are used for internal accounting only.
   * The reason they are in this structure is that the AM interface
   * requires them to be part of the TOS_Msg that is passed to
   * send/receive operations.
   */
  bool crc;
  uint16_t strength;
  uint8_t ack;
  uint16_t time;
} TOS_Msg;

typedef struct TinySec_Msg
{
  uint8_t invalid;
} TinySec_Msg;
#ifdef MICAZOLD
enum {
  MSG_DATA_SIZE = offsetof(struct TOS_Msg, crc) + sizeof(uint16_t), // 36 by default
  DATA_LENGTH = TOSH_DATA_LENGTH,
  LENGTH_BYTE_NUMBER = offsetof(struct TOS_Msg, length) + 1,
};
#endif
enum {
  // size of the header NOT including the length byte
  MSG_HEADER_SIZE = offsetof(struct TOS_Msg, data) - 1,	  //(2+1+2+2)+(TOSHeader=5)=11
  // size of the footer
  MSG_FOOTER_SIZE = 2,
  // size of the full packet-including length byte
  MSG_DATA_SIZE = offsetof(struct TOS_Msg, strength) + sizeof(uint16_t), //1+7+5+29+1+2
  // size of the data length
  DATA_LENGTH = TOSH_DATA_LENGTH,
  // position of the length byte
  LENGTH_BYTE_NUMBER = offsetof(struct TOS_Msg, length) + 1,
  // size of MAC Header 
  TOS_HEADER_SIZE = 5, 	   //TOSHeader=addr(2)+type(1)+groupid(1)+length(1)
};

typedef TOS_Msg *TOS_MsgPtr;

uint8_t TOS_MsgLength(uint8_t type)
{
#if 0
  uint8_t i;

  for (i = 0; i < MSGLEN_TABLE_SIZE; i++)
    if (msgTable[i].handler == type)
      return msgTable[i].length;
#endif

  return offsetof(TOS_Msg, crc);
}
#endif
