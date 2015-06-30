/*
 * Pulse Ox interface file
 *
 * Copyright (c) 2004,2005 Hewlett-Packard Company
 * All rights reserved
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met:

 *     * Redistributions of source code must retain the above copyright
 *       notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above
 *       copyright notice, this list of conditions and the following
 *       disclaimer in the documentation and/or other materials provided
 *       with the distribution.
 *     * Neither the name of the Hewlett-Packard Company nor the names of its
 *       contributors may be used to endorse or promote products derived
 *       from this software without specific prior written permission.

 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 * LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 *
 *
 *  Nonin Xpod Patient Cable Oximeter rev 29+
 *  5 bytes of data 75 times per second, 9600 8N1
 * 
 *  Each frame of five bytes consists of:
 *
 *    SYNC    Always = 1
 *
 *             | 7  |       6       |     5     |      4     |      3      |       2      |       1        |     0      |
 *    STATUS   | 1  |  Disconnected |  BadPulse | OutOfTrack | SensorAlarm | RedPerfusion | GreenPerfusion | Frame sync |
 *    
 *    PLETH   0-254
 *    EXTRA   
 *    CHECK   = SYNC + STATUS + PLETH + EXTRA
 *
 * 'RedPerfusion' + 'GreenPerfusion' = 'YellowPerfusion'.  Only set during EXTRA=Pulse
 * 
 * The 'FrameSync' bit is only set on frame #1.
 * The EXTRA byte is a function of the frame you are on.
 * There are 25 unique frames.
 * 
 * The EXTRA byte sent by frame is (not all frames have an extra byte)
 *
 *   1.  HR MSB        Heart rate value bits 7 & 8.  Heart rate of 511 = bad data.
 *   2.  HR LSB          LSB of above (bits 0-6).  Note that bit 7 is always 0.
 *   3.  Sp02          Sp02 value (0-100)
 *   4.  REV           Firmware revision level
 *   9.  Sp02-D        Sp02 display value with standard averaging (0-11, 127=bad data)
 *  10.  Sp02 Slew     Non-slew limited with standard averaging (0-100, 127=bad data)
 *  11.  Sp02 B-B      Beat-to-Beat value (0-100, 127 = bad data)
 *  14.  E-HR MSB      Extended averaging heart rate MSB bits 7 & 8 (511=bad data)
 *  15.  E-HR LSB        LSB of above (bits 0-6)
 *  16.  E-Sp02        Extended averaging Sp02 level (0-100)
 *  17.  E-Sp02-D      Sp02 display value with extended averaging (0-100, 127=bad data)
 *  20.  HR-D-MSB      Heart rate display value (bits 7 & 8) with standard averaging (511=bad data)
 *  21.  HR-D-LSB        LSB of above (bits 0-6)
 *  22.  E-HR-D-MSB    Heart rate display value (bits 7 & 8) with extended averaging (511=bad data)
 *  23.  E-HR-D-LSB      LSB of above (bits 0-6)
 *
 * What you really see is that we get measurements for heart rate (HR) and Sp02.
 *
 * Heart rate comes in standard, extended averaging, display, and extended averaging for display
 * Sp02 comes in standard, display, non-slew limited standard, beat-to-beat, and extended averaging.
 * 
 *   Standard:  4-beat average, updated on every pulse beat.  On 'out of track', values set to out
 *              of range immediately.
 * 
 *   Display:   Updated every 1.5 seconds.  Last 'in track' values transmitted for 10 seconds (with
 *              sensor alarm indicated).  After 10 seconds, values set to out of range.
 * 
 *   Extended:  8-beat average.
 *
 */

#ifndef __PULSE_OX_H
#define __PULSE_OX_H

enum {
  STATUS_SENSOR_DISCONNECTED = 0x40,
  STATUS_BAD_PULSE           = 0x20,
  STATUS_OUT_OF_TRACK        = 0x10,
  STATUS_SENSOR_ALARM        = 0x08,
  STATUS_RED_PERFUSION       = 0x04,
  STATUS_GREEN_PERFUSION     = 0x02,
  STATUS_FRAME_SYNC          = 0x01,

  PACKET_HR_MSB     = 0,
  PACKET_HR_LSB     = 1,
  PACKET_SPO2       = 2,
  PACKET_REV        = 3,
  PACKET_SPO2_D     = 8,
  PACKET_SPO2_SLEW  = 9,
  PACKET_SPO2_BTOB  = 10,
  PACKET_E_HR_MSB   = 13,
  PACKET_E_HR_LSB   = 14,
  PACKET_E_SPO2     = 15,
  PACKET_E_SPO2_D   = 16,
  PACKET_HR_D_MSB   = 19,
  PACKET_HR_D_LSB   = 20,
  PACKET_E_HR_D_MSB = 21,
  PACKET_E_HR_D_LSB = 22
};

struct StatusPleth {
  uint8_t status;
  uint8_t pleth;
};

enum {
  MEDIA_TYPE_OFF        = 0,
  MEDIA_TYPE_FULL       = 1, // returns struct XpodData
  MEDIA_TYPE_PULSE_ONLY = 2,// returns struct XpodDataShort
};

struct XpodDataShort {
  uint32_t number;     // A unique number for each dataset
  int      heart_rate;
  int      heart_rate_display;
  uint8_t  spo2;
  uint8_t  spo2_display;
};

// The order matches the order in XpodDataShort
struct XpodData {
  uint32_t number;     // A unique number for each dataset
  int      heart_rate;
  int      heart_rate_display;
  uint8_t  spo2;
  uint8_t  spo2_display;
  int      extended_heart_rate; 
  int      extended_heart_rate_display;
  uint8_t  spo2_slew;
  uint8_t  spo2_beat_to_beat;
  uint8_t  extended_spo2;
  uint8_t  extended_spo2_display;
  struct StatusPleth status_pleth[25];   // Status byte + pleth data
  uint8_t  firmware_rev;
};

#endif
