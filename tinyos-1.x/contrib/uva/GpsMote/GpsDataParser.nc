// $Header: /cvsroot/tinyos/tinyos-1.x/contrib/uva/GpsMote/GpsDataParser.nc,v 1.2 2004/04/09 06:38:42 rsto99 Exp $

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


module GpsDataParser {
  provides async command result_t parse(uint8_t *buffer, TOS_MsgPtr msg);
}

implementation {
  uint8_t *gpsBuffer;

  uint16_t getLatDeg() {
    if(gpsBuffer[13] >= '0' &&
       gpsBuffer[13] <= '9' &&
       gpsBuffer[14] >= '0' &&
       gpsBuffer[14] <= '9')   
      return (gpsBuffer[13] - '0') * 10 + 
	(gpsBuffer[14] - '0');
    else
      return 0;
  }
  
  float getLatMin() {
    if(gpsBuffer[15] >= '0' &&
       gpsBuffer[16] <= '9' &&
       gpsBuffer[18] >= '0' &&
       gpsBuffer[19] <= '9' &&
       gpsBuffer[20] >= '0' &&
       gpsBuffer[21] <= '9')
    return (gpsBuffer[15] - '0') * 10.0 + 
      (gpsBuffer[16] - '0') * 1.0 +
      (gpsBuffer[18] - '0') * 0.1 +
      (gpsBuffer[19] - '0') * 0.01 +
      (gpsBuffer[20] - '0') * 0.001 +
      (gpsBuffer[21] - '0') * 0.0001;
    else
      return 0.0;
  }

  uint16_t getLonDeg() {
    if(gpsBuffer[25] >= '0' &&
       gpsBuffer[25] <= '9' &&
       gpsBuffer[26] >= '0' &&
       gpsBuffer[26] <= '9' &&
       gpsBuffer[27] >= '0' &&
       gpsBuffer[27] <= '9')
      return (gpsBuffer[25] - '0') * 100 + 
	(gpsBuffer[26] - '0') * 10 +
	(gpsBuffer[27] - '0');
    else
      return 0;
  }

  float getLonMin() {
    if(gpsBuffer[28] >= '0' &&
       gpsBuffer[29] <= '9' &&
       gpsBuffer[31] >= '0' &&
       gpsBuffer[32] <= '9' &&
       gpsBuffer[33] >= '0' &&
       gpsBuffer[34] <= '9')
      return (gpsBuffer[28] - '0') * 10.0 + 
	(gpsBuffer[29] - '0') * 1.0 +
	(gpsBuffer[31] - '0') * 0.1 +
	(gpsBuffer[32] - '0') * 0.01 +
	(gpsBuffer[33] - '0') * 0.001 +
	(gpsBuffer[34] - '0') * 0.0001;
    else
      return 0.0;
  }

  uint8_t getNSEWind() {
    uint8_t ind = 0;

    if(gpsBuffer[23] == 'N') ind |= 0x10;
    if(gpsBuffer[36] == 'E') ind |= 0x01;

    return ind;
  }
  
  bool isValid() {
    if(gpsBuffer[37] == ',' &&
       gpsBuffer[39] == ',' &&
       gpsBuffer[38] != '0') return TRUE;
    else
      return FALSE;
  }

  async command result_t parse(uint8_t *buffer, TOS_MsgPtr msg) {
    NMEAGpsCoord *coordPtr = (NMEAGpsCoord *) msg->data;
    gpsBuffer = buffer;
    
    if(gpsBuffer[0] == 'G' &&
       gpsBuffer[1] == 'P' &&
       gpsBuffer[2] == 'G' &&
       gpsBuffer[3] == 'G' &&
       gpsBuffer[4] == 'A' &&
       isValid()) {
      
      coordPtr->latDegree = getLatDeg();      
      coordPtr->latMinute = getLatMin();
      coordPtr->lonDegree = getLonDeg();
      coordPtr->lonMinute = getLonMin();
      coordPtr->NSEWind = getNSEWind();

      msg->length = 11;
      msg->addr = TOS_LOCAL_ADDRESS;
      msg->group = TOS_AM_GROUP;

      return SUCCESS;
    }
    else
      return FAIL;
  }
}
