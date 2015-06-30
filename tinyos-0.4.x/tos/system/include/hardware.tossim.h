/*                                                                      tab:4
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
 * Authors:             Philip Levis
 * Description:         Declarations for TOSSIM hardware emulation.
 * Date:                September 24, 2001
 *
 */

#ifndef __HARDWARE_TOSSIM_H_INCLUDED
#define __HARDWARE_TOSSIM_H_INCLUDED

void init_hardware();

short set_io_bit(char port, char bit);
short clear_io_bit(char port, char bit);
char inp_emulate(char port);
char outp_emulate(char port, char bit);

short disable_interrupts();
short enable_interrupts();

#define PORTA 'A'
#define PINA 'A'

#define PORTB 'B'
#define PINB 'B'

#define PORTC 'C'
#define PINC 'C'

#define PORTD 'D'
#define PIND 'D'

#define PORTE 'E'
#define PINE 'E'

#define SREG 'S'

#define DDRA 'a'
#define DDRB 'b'
#define DDRC 'c'
#define DDRD 'd'
#define TCNT1H 'h'
#define TCNT1L 'l'


int a_holder_val;
#define inp(x...) a_holder_val = 0xff
#define outp(x...) a_holder_val = 0xff
//#define sbi(x...) a_holder_val = 1
//#define cbi(x...) a_holder_val = 1
//#define cli() a_holder_val = 1
//#define sei() a_holder_val = 1

#define sbi(port, bit) set_io_bit(port, bit)
#define cbi(port, bit) clear_io_bit(port, bit)
#define cli() {disable_interrupts();}
#define sei() {enable_interrupts();}
#define inp(port) inp_emulate(port)
#define outp(val, port) outp_emulate(val, port);
#endif
