/* "Copyright (c) 2000-2004 University of Virginia.  
 * All rights reserved.
 * 
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF VIRGINIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY OF
 * VIRGINIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF VIRGINIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF VIRGINIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 */

// Author: Radu Stoleru
// Date: 3/26/2004

// $Header: /cvsroot/tinyos/tinyos-1.x/contrib/uva/GpsMote/gps.h,v 1.3 2004/05/14 05:31:30 rsto99 Exp $


typedef enum {
  MAX_NUM_REPORTS_PER_GPS = 8,
  AM_GPS_CHANNEL = 157,
  FLASH_NUM_LINE_FOR_LOCALIZATION = 99
} Constants;

#define DEBUG

typedef enum {
  UNINITIALIZED,
  INITIALIZED
} LocalizationStatus;

typedef  int16_t LocalCoord;

typedef  struct {
  int32_t 	latitude;
  int32_t       longitude;
} GpsCoord;


typedef  struct {
  uint8_t   latDegree;
  float     latMinute;   //decimal minutes
  uint8_t   lonDegree;
  float     lonMinute;   //decimal minutes
  uint8_t   NSEWind;
} NMEAGpsCoord;


typedef enum {
  INIT_LOCALIZATION,
  INIT_GPS,
  RESET,
  DUMP_STATE = 9,
  DUMP_STATE_REP = 10
} GpsPacketType;


typedef struct GpsPacket {
  uint16_t        sender;
  uint8_t         type;
  char            payload[15];
} GpsPacket;


typedef struct {
  GpsCoord referencePoint;
  LocalCoord x;
  LocalCoord y;
} InitLocalizationPacket;


typedef struct {
  GpsCoord referencePoint;
  uint8_t sendingPower;
  uint16_t sendingPeriod; // in 0.1sec.
} InitGpsPacket;
