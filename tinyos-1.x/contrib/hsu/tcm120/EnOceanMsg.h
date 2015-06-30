/* 
 * Copyright (c) Helmut-Schmidt-University, Hamburg
 *		 Dpt.of Electrical Measurement Engineering  
 *		 All rights reserved
 *
 * Redistribution and use in source and binary forms, with or without 
 * modification, are permitted provided that the following conditions 
 * are met:
 * - Redistributions of source code must retain the above copyright notice,
 *   this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright 
 *   notice, this list of conditions and the following disclaimer in the 
 *   documentation and/or other materials provided with the distribution.
 * - Neither the name of the Helmut-Schmidt-University nor the names 
 *   of its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
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

 * @author Hans-Joerg Koerber 
 *         <hj.koerber@hsu-hh.de>
 *	   (+49)40-6541-2638/2627
 * $Revision: 1.1 $
 *
 */

// Message types used by EnOcean


#ifndef TOSH_DATA_LENGTH
#define TOSH_DATA_LENGTH 29
#endif

enum{
  TOSH_MDA_DATA_LENGTH = 1,
  TOSH_6DT_DATA_LENGTH = 7,
  TOSH_1BS_DATA_LENGTH = 4, 
  TOSH_4BS_DATA_LENGTH = 7,  
  TOSH_HRC_DATA_LENGTH = 4,  
  TOSH_RPS_DATA_LENGTH = 4,  
};

enum{
  TOSH_MDA_LENGTH = 5,
  TOSH_6DT_LENGTH = 11,
  TOSH_1BS_LENGTH = 8,
  TOSH_4BS_LENGTH = 11,
  TOSH_HRC_LENGTH = 8,
  TOSH_RPS_LENGTH = 8,
};

typedef struct EnOcean_6DT_Msg {
    uint8_t data[6];
    uint8_t status;
  } EnOcean_6DT_Msg;

typedef struct EnOcean_MDA_Msg {
    uint8_t status;
  } EnOcean_MDA_Msg;

typedef EnOcean_6DT_Msg *EnOcean_6DT_MsgPtr;
typedef EnOcean_MDA_Msg *EnOcean_MDA_MsgPtr;

//typedef uint8_t EnOcean_Msg;

typedef union EnOcean_Msg{
  struct EnOcean_6DT_RFMsg{ 
    uint8_t lengthRF; 
    uint8_t choice;
    uint8_t data[6];
    uint16_t id;
    uint8_t status;
    uint8_t crc;
  } EnOcean_6DT_RFMsg;

  struct  EnOcean_MDA_RFMsg{
    uint8_t lengthRF; 
    uint8_t choice;
    uint16_t id;
    uint8_t status;
    uint8_t crc;
  } EnOcean_MDA_RFMsg;
  
  struct EnOcean_1BS_RFMsg{ 
    uint8_t lengthRF; 
    uint8_t choice;
    uint8_t data[3];
    uint16_t id;
    uint8_t status;
    uint8_t chksum;
  } EnOcean_1BS_RFMsg;

  struct EnOcean_4BS_RFMsg{ 
    uint8_t lengthRF; 
    uint8_t choice;
    uint8_t data[6];
    uint16_t id;
    uint8_t status;
    uint8_t chksum;
  } EnOcean_4BS_RFMsg;

  struct EnOcean_HRC_RFMsg{ 
    uint8_t lengthRF; 
    uint8_t choice;
    uint8_t data[3];
    uint16_t id;
    uint8_t status;
    uint8_t chksum;
  } EnOcean_HRC_RFMsg;

  struct EnOcean_RPS_RFMsg{ 
    uint8_t lengthRF; 
    uint8_t choice;
    uint8_t data[3];
    uint16_t id;
    uint8_t status;
    uint8_t chksum;
  } EnOcean_RPS_RFMsg;
  
 struct  EnOcean_TOS_RFMsg{
    uint8_t lengthRF; 
    uint8_t choice;
    uint16_t addr;
    uint8_t type;
    uint8_t group;
    uint8_t length;
    uint8_t data [TOSH_DATA_LENGTH];
    uint16_t crc;
  } EnOcean_TOS_RFMsg;
} EnOceanMsg;  

typedef EnOceanMsg *EnOcean_MsgPtr;

enum{
  AM_EnOcean_MDA = 211,
  AM_EnOcean_6DT = 214,
  AM_EnOcean_1BS = 213,
  AM_EnOcean_4BS = 165,
  AM_EnOcean_HRC = 163,
  AM_EnOcean_RPS = 246,
  AM_EnOcean_TOS = 212, 
};
