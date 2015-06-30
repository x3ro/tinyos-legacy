//  $Id: timers.h,v 1.1 2005/04/15 10:00:08 hjkoerber Exp $

/* 
 * Copyright (c) Helmut-Schmidt-University, Hamburg
 *		 Dpt.of Electrical Measurement Engineering  
 *		 All rights reserved
 *
 * Redistribution and use in source and binary forms, with or without 
 * modification, are permitted provided that the following conditions 
 * are met:
 * - Redistributions of source code must retain the above copyright notice,
 *   this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright 
 *   notice, this list of conditions and the following disclaimer in the 
 *   documentation and/or other materials provided with the distribution.
 * - Neither the name of the Helmut-Schmidt-University nor the names 
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
 */

/* @author Hans-Joerg Koerber 
 *         <hj.koerber@hsu-hh.de>
 *	   (+49)40-6541-2638/2627
 * 
 * $Date: 2005/04/15 10:00:08 $
 * $Revision: 1.1 $
 *
 */

#ifndef __TIMERS_H
#define __TIMERS_H



/*
 *  The following two variables are necessary because of the         
 *  following two possibilities:                                     
 *
 *  1. A timer1-interrupt is serviced by the handler with a delay    
 *     of approximatele 2 ms due to wake-up time form sleep and the  
 *     desired timer period was less or equal than 2 ms              
 *  2. A timer1-interrupt can not be  serviced directly because       
 *     another interrupt handler is active while the timer overflows  
 *     and the delay is greater than the desired timer period        
 */

uint8_t overflow_flag;
uint16_t lostTicks;

/* Union for reading and writing timers */
union Timers
{
  unsigned int lt;
  char bt[2];
};


/*             
 * This routine writes a 16-bit value to Timer1.  
 */
void WriteTimer1(unsigned int timer1)
{
  union Timers timer;

  timer.lt = timer1;    // Save the 16-bit value in local

  TMR1H_register = timer.bt[1];  // Write low byte to Timer1 High byte
  TMR1L_register = timer.bt[0];  // Write high byte to Timer1 Low byte
}



/*                                            
 * This routine reads the 16-bit value from Timer1.                                    
 */

unsigned int ReadTimer1(void)
{
  union Timers timer;

  timer.bt[0] = TMR1L_register;    // Read Lower byte
  timer.bt[1] = TMR1H_register;    // Read upper byte

  return (timer.lt);      // Return the 16-bit value
}


#endif /* __TIMERS_H */
