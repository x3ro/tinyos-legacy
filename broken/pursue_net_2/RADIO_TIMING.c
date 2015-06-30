/*									tab:4
 * "Copyright (c) 2002 and The Regents of the University 
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
 */

#include "tos.h"
#include "RADIO_TIMING.h"

int TOS_COMMAND(GET_TIMING)(){
	//enable input capture.
	//	
	cbi(DDRB, 4);
	while(READ_RFM_RXD_PIN()){;}
	outp(0x41, TCCR1B);
	sbi(TIFR, ICF1);
	//wait for the capture.
	while((inp(TIFR) & (0x1 << ICF1)) == 0){;}
	sbi(PORTB, 6);
	cbi(PORTB, 6);
	return __inw_atomic(ICR1L);

}
int TOS_COMMAND(GET_CURRENT_TIME)(){
	return __inw_atomic(TCNT1L);
}
