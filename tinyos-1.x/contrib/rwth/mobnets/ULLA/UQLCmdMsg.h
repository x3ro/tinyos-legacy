/*
 * Copyright (c) 2007, RWTH Aachen University
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL RWTH AACHEN UNIVERSITY BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF RWTH AACHEN
 * UNIVERSITY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * RWTH AACHEN UNIVERSITY SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND RWTH AACHEN UNIVERSITY HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS.
 *
 */

/**
 *
 * Ulla Query Language header file
<p>
 * @author Krisakorn Rerkrai <kre@mobnets.rwth-aachen.de>
 **/

enum {
 AM_QUERYMSG = 8,
};


enum {
  UNUSED = 0,
  TEMPERATURE = 1,
  TSRSENSOR = 2,
  PARSENSOR = 3,
  INT_TEMP = 4,
  INT_VOLT = 5,
  RF_POWER = 6,
  LQI = 7,
  RSSI = 8,
  LED_ON = 10,
  LED_OFF = 11,
  LINK_ID = 12,
  LP_ID = 13,
  NETWORK_NAME = 14,
  TYPE = 15,
  FREQUENCY = 16,
  STATE = 17,
  RX_ENCRYPTION = 18,
  TX_ENCRYPTION = 19,
  MODE = 20,
	SUPPORTEDCLASSES = 21,
  HUMIDITY = 22,
  ALL = 198,
  NOT_DEFINED = 199,
};

enum {
 LED_TOGGLE = 21,
 LED_BLINK,
 SLEEP_MODE,
 SET_RFPOWER,
};


// UQLCmd message structure
typedef struct UQLCmdMsg {
    int8_t seqno;
    int8_t action;
    uint16_t nodeID;
    uint8_t hop_count;
    uint16_t nsamples;
    uint16_t interval;
} UQLCmdMsg;



