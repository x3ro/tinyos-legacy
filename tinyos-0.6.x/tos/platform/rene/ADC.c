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

#define IDLE 0
#define SINGLE_CONVERSION 1
#define CONTINUOUS_CONVERSION 2

char PORTMAP[PORTMAPSIZE]={
  TOS_ADC_PORT_0,
  TOS_ADC_PORT_1,
  TOS_ADC_PORT_2,
  TOS_ADC_PORT_3,
  TOS_ADC_PORT_4,
  TOS_ADC_PORT_5,
  TOS_ADC_PORT_6,
  TOS_ADC_PORT_7,
  TOS_ADC_PORT_8,
  TOS_ADC_PORT_9,
};

#define TOS_FRAME_TYPE ADC_frame
TOS_FRAME_BEGIN(ADC_frame) {
        volatile char state;
	volatile char tos_port;
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

/* ADC_SET_SAMPLING RATE */
char TOS_COMMAND(ADC_SET_SAMPLING_RATE)(char rate){
  outp((rate & 0x7), ADCSR);
  return 1;
}

static inline char TOS_EVENT(ADC_NULL_FUNC)(short data){return 0;} /* Signal data event to upper comp */

TOS_SIGNAL_HANDLER(SIG_ADC, ()){
    char tos_port = VAR(tos_port);
    int data;
    char retval = 0;
    if(VAR(state) == IDLE) return;

    data = __inw_atomic(ADCL);
    sei();

    if (VAR(state) == SINGLE_CONVERSION){
      VAR(state) = IDLE;
      cbi(ADCSR, ADEN);
      cbi(ADCSR, ADIE);
    }else {
      /* automatically starts the next conversion */
      sbi(ADCSR, ADIE);
      sbi(ADCSR, ADSC);
    }

    dbg(DBG_ADC, ("adc_tick: %d\n", tos_port));
    if(tos_port == TOS_ADC_PORT_0){	 /* Signal data event to upper comp */
    	retval = TOS_SIGNAL_EVENT(ADC_DATA_READY_PORT_0)((short)data); 
    }if(tos_port == TOS_ADC_PORT_1){
    	retval = TOS_SIGNAL_EVENT(ADC_DATA_READY_PORT_1)((short)data); 
    }if(tos_port == TOS_ADC_PORT_2){
    	retval = TOS_SIGNAL_EVENT(ADC_DATA_READY_PORT_2)((short)data); 
    }if(tos_port == TOS_ADC_PORT_3){
    	retval = TOS_SIGNAL_EVENT(ADC_DATA_READY_PORT_3)((short)data); 
    }if(tos_port == TOS_ADC_PORT_4){
    	retval = TOS_SIGNAL_EVENT(ADC_DATA_READY_PORT_4)((short)data); 
    }if(tos_port == TOS_ADC_PORT_5){
    	retval = TOS_SIGNAL_EVENT(ADC_DATA_READY_PORT_5)((short)data); 
    }if(tos_port == TOS_ADC_PORT_6){
    	retval = TOS_SIGNAL_EVENT(ADC_DATA_READY_PORT_6)((short)data); 
    }if(tos_port == TOS_ADC_PORT_7){
    	retval = TOS_SIGNAL_EVENT(ADC_DATA_READY_PORT_7)((short)data); 
    }if(tos_port == TOS_ADC_PORT_8){
    	retval = TOS_SIGNAL_EVENT(ADC_DATA_READY_PORT_8)((short)data); 
    }if(tos_port == TOS_ADC_PORT_9){
    	retval = TOS_SIGNAL_EVENT(ADC_DATA_READY_PORT_9)((short)data); 
    }

    if (VAR(state) == CONTINUOUS_CONVERSION && retval == 0){
      VAR(state) = IDLE;
      cbi(ADCSR, ADEN);
      cbi(ADCSR, ADIE);
    }
}


char TOS_COMMAND(ADC_GET_DATA)(char tos_port){
    char retval = 0;
    char prev = inp(SREG);	
    cli();

    if(VAR(state) == IDLE){ 
    	VAR(state) = SINGLE_CONVERSION;
	VAR(tos_port) = tos_port;
    	outp(ADC_PORTMAP(tos_port), ADMUX);
    	sbi(ADCSR, ADIF);
    	sbi(ADCSR, ADEN);
    	sbi(ADCSR, ADIE);
    	sbi(ADCSR, ADSC);
	retval = 1;
    }
    outp(prev, SREG);
    return retval;
}


char TOS_COMMAND(ADC_GET_CONTINUOUS_DATA)(char tos_port){
    char retval = 0;
    char prev = inp(SREG);	
    cli();

    if(VAR(state) == IDLE){ 
    	VAR(state) = CONTINUOUS_CONVERSION;
    	VAR(tos_port) = tos_port;
    	outp(ADC_PORTMAP(tos_port), ADMUX);
    	sbi(ADCSR, ADIF);
    	sbi(ADCSR, ADEN);
    	sbi(ADCSR, ADIE);
    	sbi(ADCSR, ADSC);
	retval = 1;
    }
    outp(prev, SREG);
    return retval;
}





