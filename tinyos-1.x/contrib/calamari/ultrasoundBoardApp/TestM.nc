includes Omnisound;
includes sensorboard;

module TestM {
	provides interface StdControl;
//	uses interface StdControl as SignalToAtmega8Control;
//	uses interface SignalToAtmega8;

}

implementation {

 	command result_t StdControl.init() {
//		TOSH_MAKE_INT0_OUTPUT();
		TOSH_MAKE_DEBUG1_OUTPUT();
//	    call SignalToAtmega8Control.init();
		return SUCCESS;
	}

	command result_t StdControl.start() {
		TOSH_SET_DEBUG1_PIN();
//       call SignalToAtmega8.sendSignal();
		return SUCCESS;
	}
	
	command result_t StdControl.stop() {
		return SUCCESS;
	}
   	
}
