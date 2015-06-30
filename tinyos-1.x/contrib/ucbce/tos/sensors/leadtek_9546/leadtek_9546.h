/*									tab:4
 *
 *
 * "Copyright (c) 2000-2002 The Regents of the University  of California.  
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
 */
/*									tab:4
 *  IMPORTANT: READ BEFORE DOWNLOADING, COPYING, INSTALLING OR USING.  By
 *  downloading, copying, installing or using the software you agree to
 *  this license.  If you do not agree to this license, do not download,
 *  install, copy or use the software.
 *
 *  Intel Open Source License 
 *
 *  Copyright (c) 2002 Intel Corporation 
 *  All rights reserved. 
 *  Redistribution and use in source and binary forms, with or without
 *  modification, are permitted provided that the following conditions are
 *  met:
 * 
 *	Redistributions of source code must retain the above copyright
 *  notice, this list of conditions and the following disclaimer.
 *	Redistributions in binary form must reproduce the above copyright
 *  notice, this list of conditions and the following disclaimer in the
 *  documentation and/or other materials provided with the distribution.
 *      Neither the name of the Intel Corporation nor the names of its
 *  contributors may be used to endorse or promote products derived from
 *  this software without specific prior written permission.
 *  
 *  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 *  ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 *  LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
 *  PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE INTEL OR ITS
 *  CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 *  EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 *  PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 *  PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 *  LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 *  NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 *  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * 
 */
/*
 *
 * Authors:	
 *
 */

/**
 * Parts of this code were written or modified for FireBug project
 * funded by the NSF Information Technology Research
 * initiative.  Copyright Regents of the University of 
 * of California, 2003.
 *
 * @url http://firebug.sourceforge.net
 * 
 * @author David. M. Doolin
 */


#ifndef LEADTEK_9546_H
#define LEADTEK_9546_H

const uint8_t LEADTEK_POWER_ON = 1;


// The actual values for each of these may vary,
// especially characters per field, which may be 
// application dependent.
#define GPS_MSG_LENGTH 100
#define GPS_CHAR 11
#define GGA_FIELDS 8
#define GPS_CHAR_PER_FIELD 10
#define GPS_DELIMITER ','
#define GPS_END_MSG '*'

#define GPS_DATA_LENGTH  128

#define GPS_PACKET_START 0x24   //start of gps packet
#define GPS_PACKET_END1  0x0D   //penultimate byte of NMEA string
#define GPS_PACKET_END2  0x0A   //ultimate byte of NMEA string

// Carriage return, ASCII 13
#define NMEA_END1  "\r" //0x0D   //penultimate byte of NMEA string
// Line feed, ASCII 10
#define NMEA_END2  "\n" //0x0A   //ultimate byte of NMEA string

#define NMEA_GSV_MASK "0x0001"
#define NMEA_GSA_MASK "0x0002"
#define NMEA_ZDA_MASK "0x0004"
#define NMEA_PPS_MASK "0x0010"
#define NMEA_FOM_MASK "0x0020"
#define NMEA_GLL_MASK "0x1000"
#define NMEA_GGA_MASK "0x2000"
#define NMEA_VTG_MASK "0x4000"
#define NMEA_RMC_MASK "0x8000"


/**
 * The leadtek has several different power states.
 * Each of these states should be documented here,
 * and a value defined to use when setting.  These
 * values just control the switch.  The power states
 * should be useful for setting the power and for
 * querying the driver code as to which power state 
 * the unit is currently set at.
 */
#define GPS_POWER_OFF    0
#define GPS_POWER_ON     1

const uint8_t gps_power_on = 0;


/**
 * Predefined "programs" useful for setting various states
 * of the GPS unit.  These are all in NMEA format.
 * FIXME: Find out what leadtek uses for a proprietary header string.
 */
const uint8_t gps_gga_mask[]     = {"$LTC,NMEA," NMEA_GGA_MASK NMEA_END1 NMEA_END2};
const uint8_t gps_rmc_mask[]     = {"$LTC,NMEA," NMEA_RMC_MASK NMEA_END1 NMEA_END2};
const uint8_t gps_syncmode_on[]  = {"$LTC,SYNCMODE,1" NMEA_END1 NMEA_END2};
const uint8_t gps_syncmode_off[] = {" ""$LTC,SYNCMODE,0*6F" NMEA_END1 NMEA_END2};

const uint8_t gps_test[] = {" ""$LTC,1552,1*69" NMEA_END1 NMEA_END2};
const uint8_t gps_test1[] = {" ""$LTC,1551,3,4*70" NMEA_END1 NMEA_END2};
  

const uint8_t vtg_disable[] = {" ""$PSRF103,05,00,00,01*21" NMEA_END1 NMEA_END2};

//typedef struct _gga_msg GGA_Msg;
typedef struct _gps_msg GPS_Msg;

typedef GPS_Msg * GPS_MsgPtr;


struct _gps_msg {

  /* The following fields are received on the gps. */
  uint8_t length;
  int8_t data[GPS_DATA_LENGTH];
  uint16_t crc;
};



//  18 bytes.
typedef struct GGAMsg {

  uint16_t mote_id;
  uint8_t  hours;
  uint8_t  minutes;
  float dec_sec;
  uint8_t  Lat_deg;
  float Lat_dec_min;
  uint8_t  Long_deg;
  float Long_dec_min;
  uint8_t  NSEWind; 
  uint8_t  num_sats;           
} GGAMsg;


enum {
  AM_GGAMSG = 129
};

#endif  /* LEADTEK_9546_H */
