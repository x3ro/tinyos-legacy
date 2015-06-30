/*									tab:4
 *  IMPORTANT: READ BEFORE DOWNLOADING, COPYING, INSTALLING OR USING.  By
 *  downloading, copying, installing or using the software you agree to
 *  this license.  If you do not agree to this license, do not download,
 *  install, copy or use the software.
 *
 *  Intel Open Source License 
 *
 *  Copyright (c) 2002 Intel Corporation 
 *  All rights reserved. 
 *  Redistribution and use in source and binary forms, with or without
 *  modification, are permitted provided that the following conditions are
 *  met:
 * 
 *	Redistributions of source code must retain the above copyright
 *  notice, this list of conditions and the following disclaimer.
 *	Redistributions in binary form must reproduce the above copyright
 *  notice, this list of conditions and the following disclaimer in the
 *  documentation and/or other materials provided with the distribution.
 *      Neither the name of the Intel Corporation nor the names of its
 *  contributors may be used to endorse or promote products derived from
 *  this software without specific prior written permission.
 *  
 *  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 *  ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 *  LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
 *  PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE INTEL OR ITS
 *  CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 *  EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 *  PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 *  PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 *  LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 *  NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 *  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * 
 */
/*
 *
 * Authors:		Su Ping <sping@intel-research.net>
 * Date last modified:  9/23/02
 *
 */

includes RTCtime;

module RTCC {
    provides interface RTC;
}
implementation
{
	time t ;
    bool ledOn ;

    command result_t RTC.init() {

		cbi(TIMSK, OCIE0);     //Disable TC0 interrupt
		sbi(ASSR, AS0);        //set Timer/Counter0 to be asynchronous from CPU clock
                               //with a second external clock(32,768kHz)driving it.  
		outp(0, TCNT0);		   // set timer0 counter to 0
		outp(0x5, TCCR0);      //prescale the timer to be clock/128 be clock source/128 to make it
                               //exactly 1 second for every overflow to occur
		sbi(TIMSK, TOIE0);     //enable Timer/Counter0 Overflow Interrupt Enable                             
		sei();                 //set the Global Interrupt Enable Bit  
		return SUCCESS;                          
	}

	command result_t  RTC.get(time * pt) {
		pt->second = t.second;   		
		pt->minute = t.minute;
		pt->hour   = t.hour;                                     
		pt->date   = t.date;       
		pt->month  = t.month;
		pt->year   = t.year;	
		return SUCCESS ;
	}

	command result_t RTC.set(time t1) {
		t.second = t.second;   		
		t.minute = t.minute;
		t.hour   = t.hour;                                     
		t.date   = t.date;       
		t.month  = t.month;
		t.year   = t.year;
		return SUCCESS;
	}


	//overflow interrupt vector
	TOSH_INTERRUPT(SIG_OVERFLOW0) { 
		time * tptr = &t;
    
		if (++tptr->second==60)   {			//keep track of time, date, month, and year
			tptr->second=0;
			if (++tptr->minute==60) {
			    tptr->minute=0;
				if (++tptr->hour==24) {
					tptr->hour=0;
					if (++tptr->date==32) {
						tptr->month++;
						tptr->date=1;
					} else if (tptr->date==31) {                    
						if ((tptr->month==4 || 6 || 9 || 11)) {
							tptr->month++;
							tptr->date=1;
						}
					} else if (tptr->date==30) {
						if(tptr->month==2) {
							tptr->month++;
							tptr->date=1;
						}
					}  else  if (tptr->date==29) { 
						if((tptr->month==2) && (tptr->year%4)) {
							tptr->month++;
							tptr->date=1;
						}                
					}                          
					if (tptr->month==13) {
						tptr->month=1;
						tptr->year++;
					}
				}
			}
		}  
  

