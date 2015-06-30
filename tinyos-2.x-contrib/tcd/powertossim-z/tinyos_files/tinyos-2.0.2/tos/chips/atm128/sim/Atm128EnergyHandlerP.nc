

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
