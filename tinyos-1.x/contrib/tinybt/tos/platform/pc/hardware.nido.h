/*									tab:4
 *
 *
 * "Copyright (c) 2000-2002 The Regents of the University  of California.  
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
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
 */
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
 * Authors:             Philip Levis, Nelson Lee
 * Description:         Declarations for NIDO hardware emulation.
 * Date:                September 24, 2001

 * Adopted for btnode2_2 by Mads Bondo Dydensborg, 2003.
 *
 */

#ifndef __MY_HARDWARE_NIDO_H_INCLUDED_
#define __MY_HARDWARE_NIDO_H_INCLUDED_

void init_hardware();

short set_io_bit(char port, char bit);
short clear_io_bit(char port, char bit);
char inp_emulate(char port);
char outp_emulate(char port, char bit);
short inw_emulate(char port);

short cli(void);
short set(void);

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

//needed to compile hpl.h
#define OCIE0                0x76
#define AS0                  0x77
#define OCR0                 0x78
#define ADIF                 0x79
#define EIMSK                0x80
#define INT3                 0x81
#define TCNT2                0x82

int a_holder_val;
//#define sbi(x...) a_holder_val = 1
//#define cbi(x...) a_holder_val = 1
//#define cli() a_holder_val = 1
//#define sei() a_holder_val = 1

#define sbi(port, bit) set_io_bit(port, bit)
#define cbi(port, bit) clear_io_bit(port, bit)
#define inp(port) inp_emulate(port)
#define outp(val, port) outp_emulate(val, port)
#define __inw(port) inw_emulate(port)
#define __inw_atomic(port) inw_emulate(port)

#define TOSH_ASSIGN_PIN(name, port, bit) \
static inline void TOSH_SET_##name##_PIN() {sbi(PORT##port , bit);} \
static inline void TOSH_CLR_##name##_PIN() {cbi(PORT##port , bit);} \
static inline char TOSH_READ_##name##_PIN() {return 0x01 & (inp(PIN##port) >> bit);} \
static inline void TOSH_MAKE_##name##_OUTPUT() {sbi(DDR##port , bit);} \
static inline void TOSH_MAKE_##name##_INPUT() {cbi(DDR##port , bit);} 

#define TOSH_ASSIGN_OUTPUT_ONLY_PIN(name, port, bit) \
static inline void TOSH_SET_##name##_PIN() {sbi(PORT##port , bit);} \
static inline void TOSH_CLR_##name##_PIN() {cbi(PORT##port , bit);} \
static inline void TOSH_MAKE_##name##_OUTPUT() {;} 

#define TOSH_ALIAS_OUTPUT_ONLY_PIN(alias, connector)\
static inline void TOSH_SET_##alias##_PIN() {TOSH_SET_##connector##_PIN();} \
static inline void TOSH_CLR_##alias##_PIN() {TOSH_CLR_##connector##_PIN();} \
static inline void TOSH_MAKE_##alias##_OUTPUT() {} \

#define TOSH_ALIAS_PIN(alias, connector) \
static inline void TOSH_SET_##alias##_PIN() {TOSH_SET_##connector##_PIN();} \
static inline void TOSH_CLR_##alias##_PIN() {TOSH_CLR_##connector##_PIN();} \
static inline char TOSH_READ_##alias##_PIN() {return TOSH_READ_##connector##_PIN();} \
static inline void TOSH_MAKE_##alias##_OUTPUT() {TOSH_MAKE_##connector##_OUTPUT();} \
static inline void TOSH_MAKE_##alias##_INPUT()  {TOSH_MAKE_##connector##_INPUT();} 

/* Watchdog Prescaler
 */
enum {
  TOSH_period16 = 0x00, // 47ms
  TOSH_period32 = 0x01, // 94ms
  TOSH_period64 = 0x02, // 0.19s
  TOSH_period128 = 0x03, // 0.38s
  TOSH_period256 = 0x04, // 0.75s
  TOSH_period512 = 0x05, // 1.5s
  TOSH_period1024 = 0x06, // 3.0s
  TOSH_period2048 = 0x07 // 6.0s
};

TOSH_ASSIGN_PIN(YELLOW_LED, B, 5);
TOSH_ASSIGN_PIN(GREEN_LED, B, 6);
TOSH_ASSIGN_PIN(RED_LED, B, 7);

TOSH_ASSIGN_PIN(EXTRA_LED, B, 4);

/* The uart. Uart0 is connected to the bluetooth module
   via pe0 and pe1. Uart1 is external, via pd2 and pd3. */
TOSH_ASSIGN_PIN(UART_RXD0, E, 0);
TOSH_ASSIGN_PIN(UART_TXD0, E, 1);

TOSH_ASSIGN_PIN(UART_RXD1, D, 2);
TOSH_ASSIGN_PIN(UART_TXD1, D, 3);

void TOSH_SET_PIN_DIRECTIONS(void)
{
  outp(0x00, DDRA);
  outp(0x00, DDRB);
  outp(0x00, DDRD);
  outp(0x02, DDRE);
  outp(0x02, PORTE);
  TOSH_MAKE_RED_LED_OUTPUT();
  TOSH_MAKE_YELLOW_LED_OUTPUT();
  TOSH_MAKE_GREEN_LED_OUTPUT();
  TOSH_MAKE_EXTRA_LED_OUTPUT();
  /* I think we will stop here 

  TOSH_MAKE_POT_SELECT_OUTPUT();
  TOSH_MAKE_POT_POWER_OUTPUT();
    
  TOSH_MAKE_PW7_OUTPUT();
  TOSH_MAKE_PW6_OUTPUT();
  TOSH_MAKE_PW5_OUTPUT();
  TOSH_MAKE_PW4_OUTPUT();
  TOSH_MAKE_PW3_OUTPUT();
  TOSH_MAKE_PW2_OUTPUT();
  TOSH_MAKE_PW1_OUTPUT();
  TOSH_MAKE_PW0_OUTPUT();
    
  TOSH_MAKE_RFM_CTL0_OUTPUT();
  TOSH_MAKE_RFM_CTL1_OUTPUT();
  TOSH_MAKE_RFM_TXD_OUTPUT();
  TOSH_SET_POT_POWER_PIN();

  TOSH_MAKE_FLASH_SELECT_OUTPUT();
  TOSH_MAKE_FLASH_OUT_OUTPUT();
  TOSH_MAKE_FLASH_CLK_OUTPUT();
  TOSH_SET_FLASH_SELECT_PIN();
    
  */

  TOSH_SET_RED_LED_PIN();
  TOSH_SET_YELLOW_LED_PIN();
  TOSH_SET_GREEN_LED_PIN();
  TOSH_SET_EXTRA_LED_PIN();

  /*
  TOSH_MAKE_BOOST_ENABLE_OUTPUT();
  TOSH_SET_BOOST_ENABLE_PIN();

  TOSH_MAKE_ONE_WIRE_INPUT();
  TOSH_SET_ONE_WIRE_PIN();
  */
}
#endif

