interface Atm128EnergyHandler {

// ################## MicroController state change ##################  

	async command void mcu_state_change(uint8_t powerstate);


// ################## IO Pins state change          ##################

	async command void pin_state_set(uint8_t port, uint8_t bit);
	async command void pin_state_clear(uint8_t port, uint8_t bit);
	async command void pin_state_flip(uint8_t port, uint8_t bit);



}
