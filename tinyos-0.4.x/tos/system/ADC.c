/*									tab:4
 * ADC.c - TOS abstraction of asynchronous digital photo sensor
 *
 * "Copyright (c) 2000 and The Regents of the University 
 * of California.  All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice and the following
 * two paragraphs appear in all copies of this software.
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
 * Authors:		Jason Hill
 *  modified: DEC 10/4/2000 function commented
 *
 */

/*  OS component abstraction of the analog photo sensor and */
/*  associated A/D support.  It provides an asynchronous interface */
/*  to the photo sensor. */

/*  ADC_INIT command initializes the device */
/*  ADC_GET_DATA command initiates acquiring a sensor reading. */
/*  It returns immediately.   */
/*  ADC_DATA_READY is signaled, providing data, when it becomes */
/*  available. */
/*  Access to the sensor is performed in the background by a separate */
/* TOS task. */

#include "tos.h"
#include "ADC.h"
#include "dbg.h"

#define TOS_FRAME_TYPE ADC_frame
TOS_FRAME_BEGIN(ADC_frame) {
        volatile char state;
	volatile char port;
}
TOS_FRAME_END(ADC_frame);

/* ADC_INIT: initialize the A/D to access the photo sensor */
char TOS_COMMAND(ADC_INIT)(){
    //outp(0x07, ADCSR);
 
    // set ADCSR to 0x04 for signal strength measurement 
    outp(0x04, ADCSR);
	
    cbi(ADCSR, ADSC);
    sbi(ADCSR, ADIE);
    sbi(ADCSR, ADEN);

    dbg(DBG_BOOT, ("ADC initialized.\n"));

    return 0;
}

static inline char TOS_EVENT(ADC_NULL_FUNC)(int data){return 0;} /* Signal data event to upper comp */

TOS_SIGNAL_HANDLER(_adc_, ()){
    char port = VAR(port);
    int data;
    if(VAR(state) == 0) return;
    VAR(state) = 0;

#ifdef FULLPC
    data = 0x123;
#else
    data = __inw_atomic(ADCL);
#endif

    cbi(ADCSR, ADEN);
    cbi(ADCSR, ADIE);
    sei();

    dbg(DBG_ADC, ("adc_tick: %d\n", port));
    if(port == 0){		/* Signal data event to upper comp */
    	TOS_SIGNAL_EVENT(ADC_DATA_READY_PORT_0)((int)data); 
    }if(port == 1){
    	TOS_SIGNAL_EVENT(ADC_DATA_READY_PORT_1)((int)data); 
    }if(port == 2){
    	TOS_SIGNAL_EVENT(ADC_DATA_READY_PORT_2)((int)data); 
    }if(port == 3){
    	TOS_SIGNAL_EVENT(ADC_DATA_READY_PORT_3)((int)data); 
    }if(port == 4){
    	TOS_SIGNAL_EVENT(ADC_DATA_READY_PORT_4)((int)data); 
    }if(port == 5){
    	TOS_SIGNAL_EVENT(ADC_DATA_READY_PORT_5)((int)data); 
    }if(port == 6){
    	TOS_SIGNAL_EVENT(ADC_DATA_READY_PORT_6)((int)data); 
    }if(port == 7){
    	TOS_SIGNAL_EVENT(ADC_DATA_READY_PORT_7)((int)data); 
    }
}


char TOS_COMMAND(ADC_GET_DATA)(char port){
    char retval = 0;
    char prev = inp(SREG);	
    cli();
    if(VAR(state) == 0){ 
    	VAR(state) = 1;
    	port &= 0x7;
    	VAR(port) = port;
    	outp(port, ADMUX);
    	sbi(ADCSR, ADIF);
    	sbi(ADCSR, ADEN);
    	sbi(ADCSR, ADIE);
    	sbi(ADCSR, ADSC);
	retval = 1;
    }
    outp(prev, SREG);
    return retval;
}





