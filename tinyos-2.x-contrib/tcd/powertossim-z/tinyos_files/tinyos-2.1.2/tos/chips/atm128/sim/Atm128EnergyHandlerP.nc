/*
 * Copyright (c) 2008 Trinity College Dublin.
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
 * - Neither the name of the Trinity College Dublin nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL TRINITY
 * COLLEGE DUBLIN OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
 * BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 * CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN
 * ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 */

/**
 *
 * @author Enrico Perla
 * @author Ricardo Simon Carbajo
 */

module Atm128EnergyHandlerP {
	provides {	interface Atm128EnergyHandler as Energy; }
}

implementation {

// register a MicroController State change 

uint8_t bitstate[3] = { 0, 0, 0 }; 
uint8_t active = 0;


async command void Energy.mcu_state_change(uint8_t powerstate)
{
	if ( active == 0 && powerstate == 6)
	{
		dbg("ENERGY_HANDLER", "%lld,CPU_STATE,CPU_ACTIVE\n",sim_time());
		active = 1;
		return;
	}			

	switch ( powerstate ) {
		case 0: 
			dbg("ENERGY_HANDLER", "%lld,CPU_STATE,CPU_IDLE\n", sim_time());
			break;
		case 1:
			dbg("ENERGY_HANDLER", "%lld,CPU_STATE,CPU_ADC_NOISE_REDUCTION", sim_time());
			break;
		case 2:
			dbg("ENERGY_HANDLER", "%lld,CPU_STATE,CPU_EXTENDED_STANDBY\n", sim_time());
			break;
		case 3:
			dbg("ENERGY_HANDLER", "%lld,CPU_STATE,CPU_POWER_SAVE\n", sim_time());
			break;
		case 4:    
			dbg("ENERGY_HANDLER", "%lld,CPU_STATE,CPU_STANDBY\n", sim_time());
			break;
		case 5:
			dbg("ENERGY_HANDLER", "%lld,CPU_STATE,CPU_POWER_DOWN\n", sim_time());
			break;
	}	

	active = 0;

}

async command void Energy.pin_state_set(uint8_t port, uint8_t bit)
{
	dbg("ENERGY_HANDLER", "%lld,LED_STATE,LED%d,ON\n", sim_time(), bit);
	bitstate[bit] = 1;
}

async command void Energy.pin_state_clear(uint8_t port, uint8_t bit)
{
	if ( bit == 4 ) {
		dbg("ENERGY_HANDLER","%lld,LED_STATE,LED0,OFF\n", sim_time());
		dbg("ENERGY_HANDLER","%lld,LED_STATE,LED1,OFF\n", sim_time());
		dbg("ENERGY_HANDLER","%lld,LED_STATE,LED2,OFF\n", sim_time());
		bitstate[0] = bitstate[1] = bitstate[2] = 0;
	}	
	else {
		dbg("ENERGY_HANDLER", "%lld,LED_STATE,LED%d,OFF\n",sim_time(), bit);
		bitstate[bit] = 0;
	}
}

async command void Energy.pin_state_flip(uint8_t port, uint8_t bit)
{
	if ( bitstate[bit] == 0 ) {
		bitstate[bit] = 1;
		dbg("ENERGY_HANDLER", "%lld,LED_STATE,LED%d,ON\n", sim_time(), bit);
	} else {
		bitstate[bit] = 0;
		dbg("ENERGY_HANDLER", "%lld,LED_STATE,LED%d,OFF\n", sim_time(), bit);
	}
}



}
