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
/* @(#)GDI2SoftMsg.h
 */

enum { 
  AM_GDI2SOFT_B_MSG = 52,
  AM_GDI2SOFT_WS_MSG = 53,
  AM_GDI2SOFT_B_REV2_MSG = 152,
  AM_GDI2SOFT_WS_REV2_MSG = 153,
  AM_GDI2SOFT_CALIB_MSG = 54,
  AM_GDI2SOFT_CALIB_IN_MSG = 55,
  AM_GDI2SOFT_ACK_MSG = 56,
  AM_GDI2SOFT_ACK_REV2_MSG = 156,
  AM_GDI2SOFT_RATE_MSG = 57,
  AM_GDI2SOFT_RESET_MSG = 58,
  AM_GDI2SOFT_QUERY_MSG = 59,
  AM_GDI2SOFT_NETWORK_MSG = 60,
  AM_THERMOPILE_READ_MSG  = 106,
  AM_THERMOPILE_WRITE_MSG = 107,
  AM_THERMOPILE_ACK_MSG   = 108
};

typedef struct GDI2Soft_WS_Msg {
  short source;
  uint32_t seqno;
  uint8_t sample_rate_min;
  uint8_t sample_rate_sec;
  uint16_t pressure;
  uint16_t pressure_temp;
  uint16_t humidity;
  uint16_t humidity_temp;
  uint16_t hamamatsu_top;
  uint16_t hamamatsu_bottom;
  uint8_t taos_ch0_top;
  uint8_t taos_ch0_bottom;
  uint8_t taos_ch1_top;
  uint8_t taos_ch1_bottom;
  uint16_t voltage;
} GDI2Soft_WS_Msg;

typedef struct GDI2Soft_WS_REV2_Msg {
  short source;
  uint32_t seqno;
  uint8_t sample_rate_min;
  uint8_t sample_rate_sec;
  uint16_t pressure;
  uint16_t pressure_temp;
  uint16_t humidity;
  uint16_t humidity_temp;
  uint16_t hamamatsu_top;
  uint16_t hamamatsu_bottom;
  uint8_t taos_ch0_top;
  uint8_t taos_ch0_bottom;
  uint8_t taos_ch1_top;
  uint8_t taos_ch1_bottom;
  uint16_t voltage;
  short parent;
} GDI2Soft_WS_REV2_Msg;

typedef struct GDI2Soft_B_Msg {
  short source;
  uint32_t seqno;
  uint8_t sample_rate_min;
  uint8_t sample_rate_sec;
  uint16_t thermopile;
  uint16_t therm_temp;
  uint16_t humidity;
  uint16_t humidity_temp;
  uint16_t voltage;
} GDI2Soft_B_Msg;

typedef struct GDI2Soft_B_REV2_Msg {
  short source;
  uint32_t seqno;
  uint8_t sample_rate_min;
  uint8_t sample_rate_sec;
  uint16_t thermopile;
  uint16_t therm_temp;
  uint16_t humidity;
  uint16_t humidity_temp;
  uint16_t voltage;
  short parent;
} GDI2Soft_B_REV2_Msg;

typedef struct GDI2Soft_Calib_Msg {
  short source;
  uint32_t seqno;
  uint16_t word1;
  uint16_t word2;
  uint16_t word3;
  uint16_t word4;
  uint8_t mote_type;
  uint16_t command_id;
} GDI2Soft_Calib_Msg;

typedef struct GDI2Soft_Rate_Msg {
  uint8_t sample_rate_min;
  uint8_t sample_rate_sec;
  uint8_t mote_type;
  uint16_t command_id;
  uint16_t dest;
} GDI2Soft_Rate_Msg;

typedef struct GDI2Soft_Ack_Msg {
  short source;
  uint32_t seqno;
  uint8_t sample_rate_min;
  uint8_t sample_rate_sec;
  uint8_t mote_type;
  uint16_t command_id;
  uint16_t args;
} GDI2Soft_Ack_Msg;

typedef struct GDI2Soft_Ack_REV2_Msg {
  short source;
  uint32_t seqno;
  uint8_t sample_rate_min;
  uint8_t sample_rate_sec;
  uint8_t mote_type;
  uint16_t command_id;
  uint16_t args;
  short parent;
} GDI2Soft_Ack_REV2_Msg;

typedef struct GDI2Soft_Calib_In_Msg {
  uint16_t command_id;
  uint16_t dest;
} GDI2Soft_Calib_In_Msg;

typedef struct Thermopile_Read_Msg {
  uint8_t address;
} Thermopile_Read_Msg;

typedef struct Thermopile_Write_Msg {
  uint8_t address;
  uint8_t length;
  uint16_t data[10];
} Thermopile_Write_Msg;

typedef struct Thermopile_Ack_Msg {
  uint8_t address;
  uint8_t length;
  uint16_t data[10];
} Thermopile_Ack_Msg;
