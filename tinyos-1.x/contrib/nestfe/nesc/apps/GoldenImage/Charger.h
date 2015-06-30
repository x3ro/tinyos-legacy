// $Id: Charger.h,v 1.1 2005/08/19 03:59:06 jwhui Exp $

/*									tab:2
 * "Copyright (c) 2000-2005 The Regents of the University  of California.  
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
 */

/*
 * @author Jonathan Hui <jwhui@cs.berkeley.edu>
 */

#ifndef __CHARGER_H__
#define __CHARGER_H__

enum {
  TOS_ADC_MUX0_PORT = unique( "ADCPort" ),
  TOS_ADC_MUX1_PORT = unique( "ADCPort" ),
  
  TOSH_ACTUAL_ADC_MUX0_VOLTAGE_1_5_PORT = 
  ASSOCIATE_ADC_CHANNEL( INPUT_CHANNEL_A6,
			 REFERENCE_VREFplus_AVss,
			 REFVOLT_LEVEL_1_5 ),

  TOSH_ACTUAL_ADC_MUX1_VOLTAGE_1_5_PORT = 
  ASSOCIATE_ADC_CHANNEL( INPUT_CHANNEL_A7,
			 REFERENCE_VREFplus_AVss,
			 REFVOLT_LEVEL_1_5 ),
};

#endif
