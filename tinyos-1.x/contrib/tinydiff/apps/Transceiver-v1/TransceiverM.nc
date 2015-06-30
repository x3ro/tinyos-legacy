/* 
 *	Generic.Base.c 
 *	- captures all the packets that it can hear and report it back to the UART
 *	- forward all incoming UART messages out to the radio
 */

includes AM;
includes host_mote;

module TransceiverM {
	
	provides {
		interface StdControl;
		interface ExtControl;
	}
	uses {
		interface StdControl as UARTControl;
		interface SendHostMoteMsg as UARTSend;
		interface ReceiveHostMoteMsg as UARTReceive;

//		interface Promiscuous;

		interface StdControl as RadioControl;
		interface ReceiveMsg as RadioReceive;
		interface BareSendMsg as RadioSend;

		interface Pot;
		
		interface ADC as PhotoADC;
		interface ADC as TempADC;
		interface StdControl as PhotoControl;
		interface StdControl as TempControl;
		
		interface Clock;
		
		interface Leds;
	}
}

implementation {

#include "host_mote_macros.h"

#define MAGIC 0xabcd
#define DBG_TRAN 0
#define RESET_VAR	 1
#define DONT_RESET 0

/*
 *  *  MUTEX macro
 *   *    tests and sets var, does prog if originally clear
 *    *    if reset, clears var after prog
 *     */

#define MUTEX(var, reset, prog) \
do { \
	cli(); \
	if (!var) { \
		var = 1; \
		sei(); \
	do prog while (0); \
	if (reset) var = 0; \
	} else sei(); \
} while (0)



result_t rcombine5(result_t r1, result_t r2, result_t r3,
		              result_t r4, result_t r5)
{
    return rcombine(rcombine(r1, r2), rcombine3(r3, r4, r5));
}
result_t rcombine6(result_t r1, result_t r2, result_t r3,
		              result_t r4, result_t r5, result_t r6)
{
    return rcombine(rcombine3(r1, r2, r3), rcombine3(r4, r5, r6));
}
result_t rcombine7(result_t r1, result_t r2, result_t r3,
		              result_t r4, result_t r5, result_t r6,
			                 result_t r7)
{
    return rcombine(rcombine3(r1, r2, r3), rcombine4(r4, r5, r6, r7));
}
result_t rcombine8(result_t r1, result_t r2, result_t r3,
		              result_t r4, result_t r5, result_t r6,
			                 result_t r7, result_t r8)
{
    return rcombine(rcombine4(r1, r2, r3, r4), rcombine4(r5, r6, r7, r8));
}
result_t rcombine9(result_t r1, result_t r2, result_t r3,
		              result_t r4, result_t r5, result_t r6,
			                 result_t r7, result_t r8, result_t r9)
{
    return rcombine(rcombine4(r1, r2, r3, r4), rcombine5(r5, r6, r7, r8, r9));
}


/* buffer for data from host */
TOS_Msg msg_to_radio_buffer; 
TOS_MsgPtr msg_to_radio;
int8_t msg_to_radio_busy;

/* buffer for data to host */
data_pkt data_to_host;
//hostmote_header data_to_host;
//TOS_Msg data_msg;

TOS_Msg queued_msg;
uint8_t data_to_host_busy;
uint8_t data_to_host_queued;
uint8_t data_to_host_inprogress;

/* header for CDHN message */
hostmote_header cdhn_to_host;
uint8_t cdhn_to_host_busy;

/* header and CONF/STAT message */
conf_pkt conf_to_host;
//hostmote_header conf_to_host;
//mote_conf conf;
uint8_t conf_to_host_busy;

/* header and SENS message */
sens_pkt sens_to_host;
//hostmote_header sens_to_host;
//mote_sens sens;
//uint8_t sensor_readings[32];
uint32_t sens_clock;
uint8_t sens_clock_valid;
uint8_t sens_count;
uint8_t sens_to_host_busy;

uint8_t sens_send_needed;
uint8_t sens_send_inprogress;

uint8_t conf_send_needed;
uint8_t uart_inuse;
uint8_t rdhn_pending;
uint8_t rdhn_inprogress;
uint8_t tx_led_state;
uint8_t rx_led_state;
uint8_t error_led_state;

uint16_t magic;

char tickcount;		// clock tick count, in	ticks/sec

/* *************************************************************** */
/* making led calls more readable */
static inline void rxLed_Toggle() { call Leds.redToggle(); }
static inline void rxLed_On() { call Leds.redOn(); }
static inline void rxLed_Off() { call Leds.redOff(); }
static inline void txLed_Toggle() { call Leds.greenToggle(); }
static inline void txLed_On() { call Leds.greenOn(); }
static inline void txLed_Off() { call Leds.greenOff(); }
static inline void errorLed_Toggle() { call Leds.yellowToggle(); }
static inline void errorLed_On() { call Leds.yellowOn(); }
static inline void errorLed_Off() { call Leds.yellowOff(); }
static inline void Leds_Off() { call Leds.set(0x00); }
static inline void Leds_On() { call Leds.set(0x07); }
/* *************************************************************** */


/*
 *	useful function to cast header to correct type for UART_PACKET
 */

static inline
	HostMote_MsgPtr cast_hostmote_header(hostmote_header *header)
	{ return (HostMote_MsgPtr)header; }


/* prototypes */
task void trySend();


/* Transceiver.Init:	
	 initialize lower components.
	 initialize component state, including constant portion of msgs.
*/
command result_t StdControl.init() {
	result_t ok1, ok2, ok3, ok4, ok5, ok6, ok7, ok8, ok9;

	sens_to_host.sens.type = NO_SENSORS; // indicating that sensing is disabled

	ok1 = call UARTControl.init();
	ok2 = call RadioControl.init();
	ok3 = call Leds.init();
	ok4 = call PhotoControl.init();
	ok5 = call TempControl.init();
	ok6 = call Pot.init(50);
	//Leds_Off();
	ok8 = call ExtControl.reset();
//	call Promiscuous.On();	// ON by default for the motenic


	
	// Mohan: HOSTMOTE_SYNC enabling of INT1 should have been here... but is 
	// still not in place for the micas
	
	return rcombine9(ok1, ok2, ok3, ok4, ok5, ok6, ok7, ok8, ok9);
}

command result_t StdControl.start() {
	result_t ok1, ok2, ok3, ok4;
	
	ok1 = call UARTControl.start();
	ok2 = call RadioControl.start();
	ok3 = call PhotoControl.start();
	ok4 = call TempControl.start();

	return rcombine4(ok1, ok2, ok3, ok4);
}

command result_t StdControl.stop() {
	result_t ok1, ok2, ok3, ok4, ok5;
	
	ok1 = call UARTControl.stop();
	ok2 = call RadioControl.stop();
	ok3 = call PhotoControl.stop();
	ok4 = call TempControl.stop();
	ok5 = call Clock.setRate(TOS_I0PS,TOS_S0PS);

	return rcombine5(ok1, ok2, ok3, ok4, ok5);
}

command result_t ExtControl.reset() {
	/* initialize our own state */
	memset(&msg_to_radio_buffer, 0, sizeof(TOS_Msg));
	
	msg_to_radio = &msg_to_radio_buffer;
	conf_send_needed = 0;
	sens_send_needed = 0;
	sens_send_inprogress = 0;
	magic = MAGIC;
	
	call Clock.setRate(TOS_I0PS,TOS_S0PS);	// Clock STOPPED
	conf_to_host.conf.saddr = TOS_LOCAL_ADDRESS;
	conf_to_host.conf.daddr = TOS_BCAST_ADDR;	// broadcast by default
	conf_to_host.conf.tos_group = DEF_TOS_AM_GROUP;

//	Leds_Off();
	
	dbg(DBG_TRAN, "TRANSCEIVER initialized\n");
	return SUCCESS;
}


void conf_fillmsg(uint8_t sync) {
	// MUTEX(conf_to_host_busy, RESET_VAR, prog);
	do {
		cli();
		if(!conf_to_host_busy) {
			conf_to_host_busy = 1;
			sei();
			do { // prog start
				// get timestamp
				//if(!sync) { call Time.getTime(&(conf.clock));}
				// fill header

				HOSTMOTE_SET_OP(HOSTMOTE_CONF, sync ? CONF_SYNC : CONF_STAT, &conf_to_host.header);
				HOSTMOTE_SET_FRAME(&conf_to_host.header);
				HOSTMOTE_SET_DATALEN(sizeof(mote_conf), &conf_to_host.header);
				conf_to_host.conf.saddr=TOS_LOCAL_ADDRESS;
				conf_to_host.conf.pot = call Pot.get();
				conf_send_needed = 1;
				// prog end
			} while (0); 
			if(RESET_VAR) conf_to_host_busy = 0;
		} else sei();
	} while (0);
}


static inline result_t sens_test()
{
	if(sens_send_needed) {
		// MUTEX(sens_to_host_busy, RESET_VAR, prog);
		do { // prog start
			cli();
			if(!sens_to_host_busy) {
				sens_to_host_busy = 1;
				sei();
				do {
					HOSTMOTE_SET_OP(HOSTMOTE_SENS, SENS_DATA, &sens_to_host.header);
					HOSTMOTE_SET_FRAME(&sens_to_host.header);
				HOSTMOTE_SET_DATALEN(sizeof(mote_sens) + sens_count,
															 &sens_to_host.header);
					sens_to_host.sens.clock = sens_clock;
					sens_clock_valid = 0;
					if(call UARTSend.send(cast_hostmote_header(&sens_to_host.header), 
																// Mohan: should be (sizeof(sens_pkt) - 32 +
																// sens_count): below is incorrect...
																// sizeof(sens_pkt),
																sizeof(hostmote_header) + 
																sizeof (hostmote_sens) + sens_count,
																&sens_to_host_busy)) {
						sens_send_inprogress = 1;
						sens_send_needed = 0;
						return SUCCESS;
					}
					// prog end
				} while (0);
				if(RESET_VAR) sens_to_host_busy = 0;
			} else sei();
		} while (0);
	}
	return FAIL;
}


/*
 * Trysend() tries to send some more stuff to the serial port.
 */


task void trySend()
{
	/* atomic change of uart state */
	// MUTEX(uart_inuse, RESET_VAR, prog);
	do {
		cli();
		if(!uart_inuse) {
			uart_inuse = 1;
			sei();
			do	{ // prog start
				/* need to send data to host? */
				if(data_to_host_busy) {
					if(call UARTSend.send(cast_hostmote_header(&data_to_host.header), 
																sizeof(data_pkt),
																&data_to_host_busy)) {
						data_to_host_inprogress = 1;
						goto sending;
					}
				}
				/* need to send sync/conf response? */
				else if(conf_send_needed) {
					// MUTEX(conf_to_host_busy, RESET_VAR, prog);
					do {
						cli();
						if(!conf_to_host_busy) {
							conf_to_host_busy = 1;
							sei();
							do { // prog start
								if(call UARTSend.send(
									cast_hostmote_header(&conf_to_host.header),
									sizeof(conf_pkt), &conf_to_host_busy)) {
									conf_send_needed = 0;
									goto sending;
								}
								// prog end
							} while (0);
							if(RESET_VAR) conf_to_host_busy = 0;
						} else sei();
					} while (0);
					// end MUTEX(conf_to_host_busy, RESET_VAR, prog);
				}
				/* need to send sensor data response? */
				else if(sens_test()) goto sending;

				/* send CHDN? */
				else if(rdhn_pending &&						/* if pending */
					!msg_to_radio_busy &&			// and radio is free 
					!rdhn_inprogress &&
					!cdhn_to_host_busy) {			/* and our buffer is free */
					
					cdhn_to_host_busy = 1;
					HOSTMOTE_SET_FRAME(&cdhn_to_host);
					HOSTMOTE_SET_OP(HOSTMOTE_NIC, NIC_CDHN, &cdhn_to_host);
					HOSTMOTE_SET_DATALEN(0, &cdhn_to_host);
					if(call UARTSend.send(cast_hostmote_header(&cdhn_to_host),
						sizeof(hostmote_header),
						&cdhn_to_host_busy)) {
						rdhn_inprogress = 1;
//						call Leds.greenOff();
						goto sending2;
					} else {
					}
				}
				// prog end
			} while (0);
			if(RESET_VAR) uart_inuse = 0;
		} else sei();
	} while (0);
	// end MUTEX(uart_inuse, RESET_VAR, prog);

	// Mohan: redundant...
//	call Leds.yellowToggle();
	return;
	
sending:
//	sei();
	uart_inuse=1;
//	call Leds.yellowToggle();
	return;

sending2: 
	uart_inuse=1;
//	call Leds.yellowToggle();
	return;
	
}






/*
 * This is called when a packet arrives from the transceiver and needs
 * to be sent out to the UART
 */
event TOS_MsgPtr RadioReceive.receive(TOS_MsgPtr data) {
	if(data == NULL)
		goto done;
	
	/* don't bother delivering "null" packets that sometimes arrive */
	// NOTICE: this check is disabled for now!
/*
	if(data->group == 0)
		goto done;
*/
	dbg(DBG_TRAN, "TRANSCEIVER received packet\n");
	
	/* run the RX LED */
//	rxLed_Toggle();
	
	if(data_to_host_busy) {
		
		if(data_to_host_queued) {
			dbg(DBG_TRAN, "TRANSCEIVER_RX_PACKET: dropping packet received from radio");
			errorLed_Toggle();
		}
		else {
			data_to_host_queued = 1;
			memcpy(&queued_msg, data, sizeof(TOS_Msg));
		}
		goto done;
	}	 
	dbg(DBG_TRAN, "TRANSCEIVER forwarding packet to UART\n");
	call Leds.greenToggle();

	HOSTMOTE_SET_FRAME(&data_to_host.header);
	HOSTMOTE_SET_OP(HOSTMOTE_NIC, NIC_DNH, &data_to_host.header);
	HOSTMOTE_SET_DATALEN(sizeof(TOS_Msg), &data_to_host.header);
	memcpy(&(data_to_host.msg), data, sizeof(TOS_Msg));

	// trigger output
	data_to_host_busy = 1;
	post trySend();

done:
	return data;
}
/*
 *	HOSTMOTE protocol handlers
 */

static inline void hostmote_nic(HostMote_MsgPtr data) {
	switch (HOSTMOTE_SUBOP(&(data->header))) {
	
	case NIC_DHN:
		if(msg_to_radio_busy) {
			dbg(DBG_TRAN, "!!! BUG - radio message busy, dropping packet from host\n");
			call Leds.yellowOn();
			break;
			
		}
	

		/* copy the message out to the radio */
		/* raise an error if the length is not exactly a TOS_Msg */
		if(HOSTMOTE_DATALEN(&(data->header)) != sizeof(TOS_Msg)) {
			errorLed_Toggle();
		} else {
			memcpy(msg_to_radio, data->data, sizeof(TOS_Msg));
			// NOTICE: for now, allow moted to set the source address
			// implicitly, through message construction	
/*
			if (conf_to_host.conf.saddr==0 || 
				conf_to_host.conf.saddr==TOS_BCAST_ADDR) {
				msg_to_radio->saddr=TOS_LOCAL_ADDRESS;
			} else {
				msg_to_radio->saddr=conf_to_host.conf.saddr;
			}
*/	
			dbg(DBG_TRAN, "TRANSCEIVER forwarding packet from UART to RFM\n");
			if(call RadioSend.send(msg_to_radio)==SUCCESS){
				msg_to_radio_busy=1;
				call Leds.redOn();
			} else {
				// We SHOULD be handling this case!!!
		
//				msg_to_radio_busy=1;
			}
		}
		break;
	
	case NIC_RDHN:
		rdhn_pending = 1;
//		call Leds.greenOn();
		post trySend();
		break;
	}	 
}


static inline void hostmote_conf(HostMote_MsgPtr data) {
	mote_conf *mc = (mote_conf *)data->data;

	switch (HOSTMOTE_SUBOP(&(data->header))) {
	
	case CONF_CONF:
		// set configuration parameters
		if(mc->set_flags & CONF_SET_SADDR) {
			if (mc->saddr>=0 && mc->saddr!=TOS_BCAST_ADDR)
				TOS_LOCAL_ADDRESS=mc->saddr;
			conf_to_host.conf.saddr = mc->saddr;
		}
		if(mc->set_flags & CONF_SET_DADDR)
			conf_to_host.conf.daddr = mc->daddr;
		if(mc->set_flags & CONF_SET_GROUP)
			conf_to_host.conf.tos_group = mc->tos_group;
		//if(mc->set_flags & CONF_SET_CLOCK)
		//TOS_CALL_COMMAND(TRANSCEIVER_TIMER1CLOCK_SET_TIME64)(mc->clock);
		if(mc->set_flags & CONF_SET_POT)
			call Pot.set(mc->pot);
		if(mc->set_flags & CONF_SET_BOARD)
			conf_to_host.conf.board = mc->board;

		/* fall through to send reply... */

	case CONF_STAT:

		// update conf message
		conf_fillmsg(0);
	
		// indicate ready to go and trigger output
		conf_send_needed = 1;
		post trySend();
		break;
	}
}


static inline void hostmote_sens_pkt(HostMote_MsgPtr data) {
	mote_sens *ms = (mote_sens *)data->data;

	switch (HOSTMOTE_SUBOP(&(data->header))) {
	
	case SENS_CONF:

		// need to change rate?
		if(sens_to_host.sens.delta != ms->delta) {
			/*
			if(ms->delta == 0) {
				call Clock.setRate(TOS_I1PS,TOS_S1PS);
				ms->type = 0;
			} else { 
				call Clock.setRate((ms->delta >> 8) & 0xff, ms->delta & 0xff);
			}
			*/
		}

		// set sensor params
		sens_to_host.sens = *ms;
	
		// clear sensor buffer
		sens_count = 0;
		sens_clock_valid = 0;
		
		// init report level
		if(sens_to_host.sens.report != ms->report) {
			if((ms->report > MAX_SENSOR_READINGS) || (ms->report <= 0)) { // value out of range make sane
				sens_to_host.sens.report = 16;
			} else {
				// Mohan: redundant but okay...
				sens_to_host.sens.report = ms->report;
			}
		}

		/* fall through to send reply... */
	
	case SENS_REPORT:
	
		// indicate ready to go and trigger output
		sens_send_needed = 1;
		post trySend();
		break;
	}
}

/*
 * This is called when a complete host-mote packet has arrived from
 * the UART.. dispatches to different handlers
 */

event result_t UARTReceive.receive(HostMote_MsgPtr data) {
	
	switch(HOSTMOTE_OPNUM(&(data->header))) {
	case HOSTMOTE_NOOP:
		break;

	case HOSTMOTE_RST:
		call ExtControl.reset();
		break;
		
	case HOSTMOTE_SLEEP: {

	  // reenable later...
	  /*
		cli();

		// turn off radio
		// Mohan: these three below were commented out... re-enabling them...
		TOSH_MAKE_RFM_TXD_OUTPUT();
		TOSH_MAKE_RFM_CTL0_OUTPUT();
		TOSH_MAKE_RFM_CTL1_OUTPUT();

		TOSH_CLR_RFM_TXD_PIN();
		TOSH_CLR_RFM_CTL0_PIN();
		TOSH_CLR_RFM_CTL1_PIN();

		// turn off LEDs
		Leds_Off();
	
		// set sleep mode to POWER DOWN 
		sbi(MCUCR, SM1);
		cbi(MCUCR, SM0);
		sbi(MCUCR, SE); 

		// reenable interrupts
		sei();

		asm volatile ("sleep" ::);
		asm volatile ("nop" ::);
		asm volatile ("nop" ::);

		cli();

		// restore sleep mode to IDLE
		cbi(MCUCR, SM1);

		sei();

		// reinit transceiver
		call ExtControl.reset();
	  */

		break;
	}


						 
	case HOSTMOTE_NIC:
		hostmote_nic(data);
		break;

	case HOSTMOTE_CONF:
		hostmote_conf(data);
		break;
	
	case HOSTMOTE_SENS:
		hostmote_sens_pkt(data);
		break;

	default:
		dbg(DBG_TRAN, "Unsupported packet opnum received\n");
		break;
	}
	
	return SUCCESS;
}

/*
 * Signal telling us the radio is now available to send something
 */

event result_t RadioSend.sendDone(TOS_MsgPtr msg, result_t success) {
	msg_to_radio = msg;
	msg_to_radio_busy = 0;
	call Leds.redOff();
	post trySend();
	return SUCCESS;
}


/*
 * Signal telling us the UART is now available to send something
 */

event result_t UARTSend.sendDone(HostMote_MsgPtr msg, result_t success) {
	// check for sensor data done
	if(sens_send_inprogress) {
		uint8_t i;
		uint16_t datalen = 
			HOSTMOTE_DATALEN(&(sens_to_host.header)) - sizeof(mote_sens);
		sens_send_inprogress = 0;
		if(datalen > 0) {

			cli();
			sens_count -= datalen;
			for (i=0; i<sens_count; i++) {
				sens_to_host.sensor_readings[i] = sens_to_host.sensor_readings[i+datalen];
			}
			sei();
		}
	}

	// check for queued data
	if(data_to_host_inprogress &&
		data_to_host_queued) {
		data_to_host_queued = 0;
		data_to_host_inprogress = 0;
		data_to_host_busy = 1;
		memcpy(&(data_to_host.msg), &queued_msg, sizeof(TOS_Msg));
	}

	// when we are done with the UART, mark it as free	
	if (rdhn_inprogress==1) {
		rdhn_inprogress=0;
		rdhn_pending=0;
		cdhn_to_host_busy = 0;
	}
	uart_inuse = 0;

	// retrigger output
	post trySend();
	return SUCCESS;
}


/*
* clock event does sampling, etc
*/
event result_t Clock.fire() 
{
	// Never define a sensor type of 0... 0 (NO_SENSOR) is used to check if 
	// we should request data from sensors or not

	if (sens_to_host.sens.type) {
		switch (sens_to_host.sens.type) {
		case SB_PHOTO:
			call PhotoADC.getData(); // start data reading
			break;
		case SB_TEMP:
			call TempADC.getData(); // start data reading
			break;
		default:	// trying to use non existant sensor
			break;
		}
	}
	return SUCCESS;
}

	

event result_t PhotoADC.dataReady(uint16_t data) 
{
	// store clock if needed
	if(sens_clock_valid == 0) {
		sens_clock_valid = 1;
		// will deal with timestamps on data later
		//TOS_CALL_COMMAND(TRANSCEIVER_TIMER1CLOCK_GET_TIME32)(&(sens_clock));
	}

	// This way, sens_count will never exceed MAX_SENSOR_READINGS... and
	// there won't be any array out of bounds problems...
	if (sens_count < MAX_SENSOR_READINGS) {
		sens_to_host.sensor_readings[sens_count] = data >> 2;
		sens_count++;
	}
	if(sens_count >= sens_to_host.sens.report) {
		sens_send_needed = 1;
		post trySend();
	}

	return SUCCESS;
}

event result_t TempADC.dataReady(uint16_t data) 
{
	// store clock if needed
	if(sens_clock_valid == 0) {
		sens_clock_valid = 1;
		//TOS_CALL_COMMAND(TRANSCEIVER_TIMER1CLOCK_GET_TIME32)(&(sens_clock));
	}

	// This way, sens_count will never exceed MAX_SENSOR_READINGS... and
	// there won't be any array out of bounds problems...
	if (sens_count < MAX_SENSOR_READINGS) {
		sens_to_host.sensor_readings[sens_count] = data >> 2;
		sens_count++;
	}
	if(sens_count >= sens_to_host.sens.report) {
		sens_send_needed = 1;
		post trySend();
	}

	return SUCCESS;
}
/*
	event result_t ThermalADC.dataReady(uint16_t data) {
	// store clock if needed
	if(sens_clock_valid == 0) {
	sens_clock_valid = 1;
	TOS_CALL_COMMAND(TRANSCEIVER_TIMER1CLOCK_GET_TIME32)(&(sens_clock));
	}

	sens_to_host.sensor_readings[sens_count] = data >> 2;
	sens_count++;
	if(sens_count >= sens.report) {
	sens_send_needed = 1;
	post trySend();
	}

	return SUCCESS;
	}
*/

}
