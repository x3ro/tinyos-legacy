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

// Authors: Cory Sharp
// $Id: sensorboard.h,v 1.3 2004/03/16 03:44:04 cssharp Exp $

enum
{
  TOS_ADC_MAG_X_PORT = 2,
  TOS_ADC_MAG_Y_PORT = 3,
  X9259_I2C_DEVICE_TYPE = 5,
  X9259_I2C_DEVICE_ADDR = 0,
  TOS_X9259_I2CPACKET_ID = (X9259_I2C_DEVICE_TYPE << 4) | X9259_I2C_DEVICE_ADDR,
};

#define HDMAG_MAKE_SETRESET_CLOCK_OUTPUT() TOSH_MAKE_GPS_ENA_OUTPUT()
#define HDMAG_SET_SETRESET_CLOCK()         TOSH_SET_GPS_ENA_PIN()
#define HDMAG_CLEAR_SETRESET_CLOCK()       TOSH_CLR_GPS_ENA_PIN()

#ifndef PLATFORM_PC
TOSH_ALIAS_PIN(MAG_CTL, PW1);
TOSH_ALIAS_PIN(BOOST_5V_CTL, ADC6);
#endif //PLATFORM_PC

