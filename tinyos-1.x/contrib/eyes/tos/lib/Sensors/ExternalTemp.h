/*
 * Copyright (c) 2004, Technische Universitaet Berlin
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without 
 * modification, are permitted provided that the following conditions 
 * are met:
 * - Redistributions of source code must retain the above copyright notice,
 *   this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright 
 *   notice, this list of conditions and the following disclaimer in the 
 *   documentation and/or other materials provided with the distribution.
 * - Neither the name of the Technische Universitaet Berlin nor the names 
 *   of its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS 
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT 
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT 
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, 
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED 
 * TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, 
 * OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY 
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT 
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE 
 * USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * - Revision -------------------------------------------------------------
 * $Revision: 1.3 $
 * $Date: 2005/07/07 21:15:29 $
 * @author Jan Hauer <hauer@tkn.tu-berlin.de>
 * ========================================================================
 */


#ifndef EXTERNAL_TEMP_H 
#define EXTERNAL_TEMP_H

#include "MSP430ADC12.h"
enum
{
  TOS_ADC_EXTERNAL_TEMP_PORT = unique("ADCPort"),
  TOSH_ACTUAL_ADC_EXTERNAL_TEMP_PORT = ASSOCIATE_ADC_CHANNEL( 
      INPUT_CHANNEL_A0, 
      REFERENCE_VREFplus_AVss, 
      REFVOLT_LEVEL_1_5)
};

#define MSP430ADC12_EXTERNAL_TEMP_SETTINGS ADC12_SETTINGS( \
           INPUT_CHANNEL_A0, REFERENCE_VREFplus_AVss, SAMPLE_HOLD_4_CYCLES, \
           SHT_SOURCE_SMCLK, SHT_CLOCK_DIV_1, SAMPCON_SOURCE_SMCLK, \
           SAMPCON_CLOCK_DIV_1, REFVOLT_LEVEL_1_5)           

#endif

