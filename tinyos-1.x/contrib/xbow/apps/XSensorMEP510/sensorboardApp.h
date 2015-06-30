/**
 * Copyright (c) 2004-2005 Crossbow Technology, Inc.  All Rights Reserved.
 *
 * Permission to use, copy, modify and distribute, this software and 
 * documentation is granted, provided the following conditions are met:
 *   1. The above copyright notice and these conditions, along with the 
 *      following disclaimers, appear in all copies of the software.
 *   2. When the use, copying, modification or distribution is for COMMERCIAL 
 *      purposes (i.e., any use other than academic research), then the 
 *      software (including all modifications of the software) may be used 
 *      ONLY with hardware manufactured by and purchased from 
 *      Crossbow Technology, unless you obtain separate written permission 
 *      from, and pay appropriate fees to, Crossbow.  For example, no right 
 *      to copy and use the software on non-Crossbow hardware, if the use is 
 *      commercial in nature, is permitted under this license. 
 *   3. When the use, copying, modification or distribution is for 
 *      NON-COMMERCIAL PURPOSES (i.e., academic research use only), the 
 *      software may be used, whether or not with Crossbow hardware, 
 *      without any fee to Crossbow. 
 *
 * IN NO EVENT SHALL CROSSBOW TECHNOLOGY OR ANY OF ITS LICENSORS BE LIABLE TO 
 * ANY PARTY FOR DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL 
 * DAMAGES ARISING OUT OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN 
 * IF CROSSBOW OR ITS LICENSOR HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH 
 * DAMAGE. CROSSBOW TECHNOLOGY AND ITS LICENSORS SPECIFICALLY DISCLAIM ALL 
 * WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF 
 * MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE SOFTWARE PROVIDED 
 * HEREUNDER IS ON AN "AS IS" BASIS, AND NEITHER CROSSBOW NOR ANY LICENSOR HAS 
 * ANY OBLIGATION TO PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, 
 * OR MODIFICATIONS. 
 *
 * $Id: sensorboardApp.h,v 1.1 2005/02/03 09:28:14 pipeng Exp $
 */



// controls for the voltage reference monitor
#define MAKE_BAT_MONITOR_OUTPUT() sbi(DDRC, 7)
#define MAKE_ADC_INPUT() cbi(DDRF, 1)
#define SET_BAT_MONITOR() cbi(PORTC, 7)
#define CLEAR_BAT_MONITOR() sbi(PORTC, 7)

//controls for the thermistor sensor
#define MAKE_THERM_OUTPUT() sbi(DDRC,6)
#define SET_THERM_POWER() cbi(PORTC,6)
#define CLEAR_THERM_POWER() sbi(PORTC,6)


// crossbow sensor board id
#define  SENSOR_BOARD_ID 0x03               //MTS500 sensor board id


typedef struct XSensorHeader{
  uint8_t  board_id;
  uint8_t  packet_id; // 3
  uint8_t  node_id;
  uint8_t  rsvd;
}__attribute__ ((packed)) XSensorHeader;

typedef struct PData1 {
  uint8_t  vref;
  uint16_t thermistor;
  uint16_t humidity;
  uint16_t humtemp; // 13
} __attribute__ ((packed)) PData1;


typedef struct XDataMsg {
  XSensorHeader xSensorHeader;
  PData1 xData;

} __attribute__ ((packed)) XDataMsg;

enum {
  AM_XSXMSG = 0,
  
};

enum {
    BATT_PORT = 1,             //adc port for battery voltage
};


