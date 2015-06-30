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
short inw_emulate(char port);

short disable_interrupts();
short enable_interrupts();

#define SREG                 0x00
#define SPH                  0x01
#define SPL                  0x02
#define GIMSK                0x03
#define GIFR                 0x04
#define TIMSK                0x05
#define TIFR                 0x06
#define SPMCR                0x07
#define TWCR                 0x08
#define MCUCR                0x09
#define MCUSR                0x10
#define TCCR0                0x11
#define TCNT0                0x12
#define OSCCAL               0x13
#define SFIOR                0x14

#define TCCR1A               0x15
#define TCCR1B               0x16
#define TCNT1H               0x17
#define TCNT1L               0x18

#define OCR1AH               0x19
#define OCR1AL               0x20
#define OCR1BH               0x21
#define OCR1BL               0x22

#define ICR1H                0x23
#define ICR1L                0x24
#define TCCR2                0x25
#define OCR2                 0x26
#define ASSR                 0x27
#define WDTCR                0x28
#define UBRRHI               0x29
#define EEARH                0x30
#define EEARL                0x31
#define EEDR                 0x32
#define EECR                 0x33

#define PORTA                0x34
#define PINA                 0x35
#define DDRA                 0x36

#define PORTB                0x37
#define PINB                 0x38
#define DDRB                 0x39

#define PORTC                0x40
#define PINC                 0x41
#define DDRC                 0x42

#define PORTD                0x43
#define PIND                 0x44
#define DDRD                 0x45

#define SPDR                 0x46
#define SPSR                 0x47
#define SPCR                 0x48

#define UDR                  0x49
#define UCSRA                0x50
#define UCSRB                0x51
#define UBRR                 0x52
#define ACSR                 0x53
#define ADMUX                0x54

#define ADCSR                0x55
#define ADCH                 0x56

#define ADCL                 0x57
#define TWDR                 0x58
#define TWAR                 0x59
#define TWSR                 0x60
#define TWBR                 0x61

#define ADEN                 0x62
#define ADIE                 0x63
#define ADSC                 0x64

#define OCIE1A               0x65
#define TICIE1               0x66
#define TOIE0                0x67
#define TOIE1                0x68
#define OCIE1B               0x69

#define PORTE                0x70
#define PINE                 0x71
#define DDRE                 0x72

#define UCR                  0x73
#define USR                  0x74
#define TXC                  0x75

int a_holder_val;
//#define sbi(x...) a_holder_val = 1
//#define cbi(x...) a_holder_val = 1
//#define cli() a_holder_val = 1
//#define sei() a_holder_val = 1

#define sbi(port, bit) set_io_bit(port, bit)
#define cbi(port, bit) clear_io_bit(port, bit)
#define cli() disable_interrupts()
#define sei() enable_interrupts()
#define inp(port) inp_emulate(port)
#define outp(val, port) outp_emulate(val, port)
#define __inw(port) inw_emulate(port)
#define __inw_atomic(port) inw_emulate(port)
#endif
