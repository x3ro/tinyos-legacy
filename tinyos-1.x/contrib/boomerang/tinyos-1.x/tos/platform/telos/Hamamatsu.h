//$Id: Hamamatsu.h,v 1.1.1.1 2007/11/05 19:10:37 jpolastre Exp $

/* "Copyright (c) 2000-2003 The Regents of the University of California.  
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement
 * is hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY
 * OF CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 */

//@author Cory Sharp <cssharp@eecs.berkeley.edu>

#ifndef _H_Hamamatsu_h
#define _H_Hamamatsu_h

#include "MSP430ADC12.h"

// PAR, Photosynthetically Active Radiation
enum
{
  TOS_ADC_PAR_PORT = unique("ADCPort"),

  TOSH_ACTUAL_ADC_PAR_PORT = ASSOCIATE_ADC_CHANNEL(
    INPUT_CHANNEL_A4, 
    REFERENCE_VREFplus_AVss, 
    REFVOLT_LEVEL_1_5
  )
};

#define MSP430ADC12_PAR ADC12_SETTINGS( \
           INPUT_CHANNEL_A4, REFERENCE_VREFplus_AVss, SAMPLE_HOLD_4_CYCLES, \
           SHT_SOURCE_ACLK, SHT_CLOCK_DIV_1, SAMPCON_SOURCE_SMCLK, \
           SAMPCON_CLOCK_DIV_1, REFVOLT_LEVEL_1_5) 

// TSR, Total Solar Radiation
enum
{
  TOS_ADC_TSR_PORT = unique("ADCPort"),

  TOSH_ACTUAL_ADC_TSR_PORT = ASSOCIATE_ADC_CHANNEL(
    INPUT_CHANNEL_A5, 
    REFERENCE_VREFplus_AVss,
    REFVOLT_LEVEL_1_5
  )
};

#define MSP430ADC12_TSR ADC12_SETTINGS( \
           INPUT_CHANNEL_A5, REFERENCE_VREFplus_AVss, SAMPLE_HOLD_4_CYCLES, \
           SHT_SOURCE_ACLK, SHT_CLOCK_DIV_1, SAMPCON_SOURCE_SMCLK, \
           SAMPCON_CLOCK_DIV_1, REFVOLT_LEVEL_1_5) 

#endif//_H_Hamamatsu_h

