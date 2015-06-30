// $Id: AM.h,v 1.1 2005/04/14 08:08:34 hjkoerber Exp $

/*								
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
 * @author Jason Hill
 * @author David Gay
 * @author Philip Levis
 * @author Chris Karlof
 * @author Hans-Joerg Koerber 
 *         <hj.koerber@hsu-hh.de>
 *	   (+49)40-6541-2638/2627
 *
 * $Date: 2005/04/14 08:08:34 $
 * $Revision: 1.1 $
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
#define TOSH_DATA_LENGTH 29
#endif

#ifndef TOSH_AM_LENGTH
#define TOSH_AM_LENGTH 1
#endif

#ifndef TOSH_CHOICE
#define TOSH_TOS_CHOICE 212 // = 0xd4
#endif



typedef struct TOS_Msg
{
 
  /* LengthRF is only needed by the assembler transmit routine,
   * because the rouinte must know how many bytes are transmitted
   * over the radio actually.
   * In the case of changes of this struct it must remain at the
   * first position
   */  

  //  uint8_t lengthRF; 
  
  /* The following fields are transmitted/received on the radio. */

  // uint8_t choice; //this byte is needed to be compatible to the EnOcean meesage types, which also use the choice index
  uint16_t addr;
  uint8_t type;
  uint8_t group;
  uint8_t length;
  uint8_t data[TOSH_DATA_LENGTH];
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

enum {
  MSG_DATA_SIZE = 36,
  TINYSEC_MSG_DATA_SIZE = 41,
  DATA_LENGTH = TOSH_DATA_LENGTH,
  LENGTH_BYTE_NUMBER = 5,
  TINYSEC_NODE_ID_SIZE = 2
};

typedef TOS_Msg *TOS_MsgPtr;


#endif
