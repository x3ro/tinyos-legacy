/* 
 * Copyright (c) 2005, Ecole Polytechnique Federale de Lausanne (EPFL), Switzerland
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
 * - Neither the name of the Ecole Polytechnique Federale de Lausanne nor the names
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
 * ========================================================================
 */

/*
 *
 * Platform definitions for tinynode solarboard.
 *
 * Author: Henri Dubois-Ferriere
 *
 */
#ifndef _H_solarboard_h
#define _H_solarboard_h



// Open questions:
// Ref voltage for two ADC inputs
// What should the default value for all data outputs be

// Solar board
TOSH_ALIAS_PIN(SBD_MUXA1, SIMO1);          // MUX 1
TOSH_ALIAS_PIN(SBD_MUXA0, STE1);         // MUX 0
TOSH_ALIAS_PIN(SBD_SHDN_DC_DC_2, P23);    // Li-Ion charge command (1 -> charge)
TOSH_ALIAS_PIN(SBD_EN_BAT, UCLK1);        // Energy source selection (1 -> Bat, 0 -> supercap)
TOSH_ALIAS_PIN(SBD_EN_MULT, SOMI1);       // Command of EN_MULT MUX (should be 0 when not measuring anything)
TOSH_ALIAS_PIN(SBD_EXT_INT, P24);         // External interrupt
TOSH_ALIAS_PIN(SBD_SENS_VSUP, P16);       // Power supply for sensors
TOSH_ALIAS_PIN(SBD_VSUP, ADC2);           // channel 2: supply monitor from solar board (voltage)
TOSH_ALIAS_PIN(SBD_CSUP, ADC3);           // channel 3: supply monitor from solar board (current)

//REFERENCE_VREFplus_AVss, 
// associate ADC channels
enum
{
	TOSH_ADC_SBD_VSUP_PORT = unique("ADCPort"),
	TOSH_ACTUAL_ADC_SBD_VSUP_PORT = ASSOCIATE_ADC_CHANNEL(
								INPUT_CHANNEL_A2, 
								REFERENCE_VREFplus_AVss, 
								REFVOLT_LEVEL_1_5
								),

	TOSH_ADC_SBD_CSUP_PORT = unique("ADCPort"),
	TOSH_ACTUAL_ADC_SBD_CSUP_PORT = ASSOCIATE_ADC_CHANNEL(
								INPUT_CHANNEL_A3, 
								REFERENCE_VREFplus_AVss,
								REFVOLT_LEVEL_1_5
								),
};
#endif // _H_solarboard_h
