/*									tab:4
 *
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
 *
 *
 */



/*
 * This component performs bit level control over the RF Monolitics radio.
 * Addtionally, it controls the amount of time per bit by using TCNT1.
 * The sample period can be set to 1/2x, 3/4x, and x. Where x is the 
 * bit transmisison period. 1/2 and 3/4 are provided to do sampling 
 * and then read at the point half way between samples.
 *
 * Now added states to do carrier sense.  180us and 20us.
 * Bit rate 0 is now 20 us and state 3 has the functionality of old state 0
 */



#include "tos.h"
#include "RFM_LOW_POWER.h"
#include "dbg.h"

#define TOS_FRAME_TYPE RFM_frame
TOS_FRAME_BEGIN(RFM_frame) {
        char state;
        char count;
}
TOS_FRAME_END(RFM_frame);

//states:
// 0 == receive mode;
// 1 == transmit mode;
// 2 == low power mode;
// 3 == waiting for carrier sense;

//these are for 100us on, 100us off
//#define OFFTIME_H 0x01
//#define OFFTIME_L 0x90
//#define ONTIME_H 0x01
//#define ONTIME_L 0x90

//these are for 20us on, 180us off
//which acutally runs as 30, 190.
//#define OFFTIME_H 0x02
//#define OFFTIME_L 0xD0
//#define ONTIME_H 0x00
//#define ONTIME_L 0x50

//these are for 20us on, 260us off
//which acutally runs as 30, 270.
#define OFFTIME_H 0x04
#define OFFTIME_L 0x10
#define ONTIME_H 0x00
#define ONTIME_L 0x50

#ifdef DEBUG
#undef DEBUG
#endif


TOS_SIGNAL_HANDLER(SIG_OUTPUT_COMPARE1A, ()) {
    //dbg(DBG_RADIO, ("state %d, bitIn %d, first: %x\n", VAR(state), bitIn, VAR(first)));
    int avilable = 0;
	char in;

    //debug: set this pin high at the start of interrupt so 
    // sample times can me measured on a scope.

    if(VAR(state) == 1){
	//if we are writing, then fire the bit send event.
	TOS_SIGNAL_EVENT(RFM_TX_BIT_EVENT)(); 
    } else if(VAR(state) == 0){
	//if we are reading, read in the value.
        in = READ_RFM_RXD_PIN();

	//fire the bit arrived event and send up the value.
	if(in == 0){
		VAR(count) ++;
	}else{
		VAR(count) = 0;
	}
	TOS_SIGNAL_EVENT(RFM_RX_BIT_EVENT)(in);
	if(VAR(count) > 6) VAR(state) = 3;

    }else if(VAR(state) == 3){
       VAR(state) = 4;
       outp(ONTIME_H, OCR1AH); // set upper byte of comp reg.
       outp(ONTIME_L, OCR1AL); // set the lower byte compare
       SET_RFM_CTL0_PIN();
       SET_RFM_CTL1_PIN();
   }else if(VAR(state) == 4){
       in = READ_RFM_RXD_PIN();
       if(in){
	        TOS_CALL_COMMAND(RFM_SET_BIT_RATE)(3);
	        VAR(state) = 0;
	        VAR(count) = 0;
	        TOS_SIGNAL_EVENT(RFM_RX_BIT_EVENT)(1);
       }else{
	        VAR(state) = 3;
	        outp(OFFTIME_H, OCR1AH); // set upper byte of comp reg.
	        outp(OFFTIME_L, OCR1AL); // set the lower byte compare
	        CLR_RFM_CTL0_PIN();
	        CLR_RFM_CTL1_PIN();
	        TOS_SIGNAL_EVENT(RFM_RX_BIT_EVENT)(0);
       }
	
   }
  sbi(TIFR, OCF1A); // enable timer1 interupt
}

 char TOS_COMMAND(RFM_TX_BIT)(char data){
     //if not in the transmit mote fail.
     if(VAR(state) != 1) return 0;
    //SET_RFM_CTL0_PIN();
    //CLR_RFM_CTL1_PIN();
	//sent the output pin accordingly.
        if(data & 0x01){
            SET_RFM_TXD_PIN();
        }
        else{
            CLR_RFM_TXD_PIN();
        }
       return 1;
 }

 char TOS_COMMAND(RFM_PWR)(char mode){
if(mode == 0){
    //turn off the RFM chip.
    CLR_RFM_CTL0_PIN();
    CLR_RFM_CTL1_PIN();
	// disable timer1 interupt
    outp(0x00, TCCR1B); // scale the counter
    cbi(TIMSK, OCIE1A); 
    //record the current state.
     VAR(state) = 2;
}else if(mode == 1){
    VAR(state) = 3;
    outp(0x09, TCCR1B); // scale the counter
    sbi(TIMSK, OCIE1A); 
}
     return 1;
 }



 char TOS_COMMAND(RFM_TX_MODE)(){
    //set the RFM chip to TX mode.
    SET_RFM_CTL0_PIN();
    CLR_RFM_CTL1_PIN();

	dbg(DBG_RADIO, ("RADIO: set TX mode....\n"));

    //record the current state.
     VAR(state) = 1;
	return 1;
 }
 char TOS_COMMAND(RFM_RX_MODE)(){
    //set the RFM to RX mode.
    SET_RFM_CTL0_PIN();
    SET_RFM_CTL1_PIN();
    CLR_RFM_TXD_PIN();

	dbg(DBG_RADIO, ("RADIO: set RX mode....\n"));

    //record the current state.
     TOS_CALL_COMMAND(RFM_SET_BIT_RATE)(3);
     VAR(state) = 4;
     return 1;
}

char TOS_COMMAND(RFM_SET_BIT_RATE)(char level){
    if(level == 3){
	outp(0x00, OCR1AH); // set upper byte of comp reg.
	outp(0xc8, OCR1AL); // set the lower byte compare
    	outp(0x00, TCNT1H); // clear current counter value
    	outp(0x00, TCNT1L); // clear current couter high byte value
    }else if(level == 1){
	outp(0x01, OCR1AH); // set upper byte of comp reg.
	outp(0x2c, OCR1AL); // set the lower byte compare
    }else if(level == 2){
	 outp(0x01, OCR1AH); // set upper byte of comp reg.
	 outp(0x90, OCR1AL); // set the lower byte compare
    }else if(level == 0){
	    outp(ONTIME_H, OCR1AH); // set upper byte of comp reg.
	    outp(ONTIME_L, OCR1AL); // set the lower byte compare
	    outp(0x00, TCNT1H); // clear current counter value
    	outp(0x00, TCNT1L); // clear current couter high byte value
    }
	return 1;
}


 char TOS_COMMAND(RFM_INIT)(){
    //assume RX_state.
    VAR(state) = 0;
    VAR(count) = 0;


    //set the RFM pins.
    SET_RFM_CTL0_PIN();
    SET_RFM_CTL1_PIN();
    CLR_RFM_TXD_PIN();

    cbi(TIMSK, OCIE1A); //cear interrupts
    cbi(TIMSK, TICIE1); //cear interrupts
    cbi(TIMSK, TOIE1); //cear interrupts
    cbi(TIMSK, OCIE1B); //cear interrupts
    outp(0x09, TCCR1B); // scale the counter
    outp(0x09, TCCR1B); // scale the counter
    outp(0x00, TCCR1A);
    outp(0x00, OCR1AH); // set upper byte of comp reg.
    outp(0xc8, OCR1AL); // set the lower byte compare
    sbi(TIMSK, OCIE1A); // enable timer1 interupt
    outp(0x00, TCNT1H); // clear current counter value
    outp(0x00, TCNT1L); // clear current couter high byte value
    sei(); //enable system interrupts.

	return 1;
 }
