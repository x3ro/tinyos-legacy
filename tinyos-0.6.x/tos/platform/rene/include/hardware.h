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
 * Authors:             Jason Hill
 *
 *
 */

#ifndef __HARDWARE__
#define __HARDWARE__

#define RENE 1
#ifdef FULLPC

#ifdef TOSSIM

#include <time.h>
#include "hardware.tossim.h"

#else // FULLPC follows

#include <time.h>
int a_holder_val;
#define inp(x...) a_holder_val = 1
#define outp(x...) a_holder_val = 1
#define sbi(x...) a_holder_val = 1
#define cbi(x...) a_holder_val = 1
#define cli() a_holder_val = 1
#define sei() a_holder_val = 1

#endif // TOSSIM

#else //FULLPC
#include "io.h"
#include "sig-avr.h"
#include "interrupt.h"
#include "wdt.h"


//this macro automatically drops any printf statements if not
//compiling for a PC
#define printf(x...) ;


#endif //FULLPC

#define ASSIGN_PIN(name, port, bit) \
static inline void SET_##name##_PIN() {sbi(PORT##port , bit);} \
static inline void CLR_##name##_PIN() {cbi(PORT##port , bit);} \
static inline char READ_##name##_PIN() {return 0x01 & (inp(PIN##port) >> bit);} \
static inline void MAKE_##name##_OUTPUT() {sbi(DDR##port , bit);} \
static inline void MAKE_##name##_INPUT() {cbi(DDR##port , bit);} 

#define ALIAS_PIN(alias, connector) \
static inline void SET_##alias##_PIN() {SET_##connector##_PIN();} \
static inline void CLR_##alias##_PIN() {CLR_##connector##_PIN();} \
static inline char READ_##alias##_PIN() {return READ_##connector##_PIN();} \
static inline void MAKE_##alias##_OUTPUT() {MAKE_##connector##_OUTPUT();} \
static inline void MAKE_##alias##_INPUT()  {MAKE_##connector##_INPUT();} 

#define ASSIGN_OUTPUT_ONLY_PIN(name, port, bit) \
static inline void SET_##name##_PIN() {sbi(PORT##port , bit);} \
static inline void CLR_##name##_PIN() {cbi(PORT##port , bit);} \
static inline void MAKE_##name##_OUTPUT() {;} 

#define ALIAS_OUTPUT_ONLY_PIN(alias, connector)\
static inline void SET_##alias##_PIN() {SET_##connector##_PIN();} \
static inline void CLR_##alias##_PIN() {CLR_##connector##_PIN();} \
static inline void MAKE_##alias##_OUTPUT() {;} \

ASSIGN_PIN(RED_LED, C, 5);
ASSIGN_PIN(YELLOW_LED, C, 3);
ASSIGN_PIN(GREEN_LED, C, 4);

ASSIGN_PIN(UD, C, 4);
ASSIGN_PIN(INC, C, 5);
ASSIGN_PIN(POT_SELECT, C, 2);

ASSIGN_PIN(RFM_RXD,  D, 2);
ASSIGN_PIN(RFM_TXD,  B, 2);
ASSIGN_PIN(RFM_CTL0, B, 0);
ASSIGN_PIN(RFM_CTL1, B, 1);

ASSIGN_PIN(PW1, B, 4);
ASSIGN_PIN(PW2, B, 3);
ASSIGN_PIN(PW3, D, 5);
ASSIGN_PIN(PW4, D, 6);

ASSIGN_PIN(I2C_BUS1_SCL, D, 3);
ASSIGN_PIN(I2C_BUS1_SDA, D, 4);
ASSIGN_PIN(I2C_BUS2_SCL, C, 0);
ASSIGN_PIN(I2C_BUS2_SDA, C, 1);

ASSIGN_PIN(LITTLE_GUY_RESET, D, 7);

ASSIGN_PIN(UART_RXD0, D, 0);
ASSIGN_PIN(UART_TXD0, D, 1);

static inline void SET_PIN_DIRECTIONS(){
    outp(0x00, DDRA);
    outp(0x00, DDRB);
    outp(0x00, DDRC);
    outp(0x00, DDRD);
    MAKE_RED_LED_OUTPUT();
    MAKE_YELLOW_LED_OUTPUT();
    MAKE_GREEN_LED_OUTPUT();
    MAKE_POT_SELECT_OUTPUT();
    
    MAKE_PW4_OUTPUT();
    MAKE_PW3_OUTPUT();
    MAKE_PW2_OUTPUT();
    MAKE_PW1_OUTPUT();
    
    MAKE_RFM_CTL0_OUTPUT();
    MAKE_RFM_CTL1_OUTPUT();
    MAKE_RFM_TXD_OUTPUT();
    
    SET_RED_LED_PIN();
    SET_YELLOW_LED_PIN();
    SET_GREEN_LED_PIN();
}

/* Watchdog Prescaler
 */
#define period16 0x00 // 47ms
#define period32 0x01 // 94ms
#define period64 0x02 // 0.19s
#define period128 0x03 // 0.38s
#define period256 0x04 // 0.75s
#define period512 0x05 // 1.5s
#define period1024 0x06 // 3.0s
#define period2048 0x07 // 6.0s

/* Clock scale
 * 0 - off
 * 1 - 32768 ticks/second
 * 2 - 4096 ticks/second
 * 3 - 1024 ticks/second
 * 4 - 512 ticks/second
 * 5 - 256 ticks/second
 * 6 - 128 ticks/second
 * 7 - 32 ticks/second
 */

#define tick1000ps 33,1
#define tick100ps 41,2
#define tick10ps 102,3
#define tick4096ps 1,2
#define tick2048ps 2,2
#define tick1024ps 1,3
#define tick512ps 2,3
#define tick256ps 4,3
#define tick128ps 8,3
#define tick64ps 16,3
#define tick32ps 32,3
#define tick16ps 64,3
#define tick8ps 128,3
#define tick4ps 128,4
#define tick2ps 128,5
#define tick1ps 128,6

/* ADC sampling scale
 */
#define sample3750ns 0
#define sample7500ns 1
#define sample15us   2
#define sample30us   3
#define sample60us   4
#define sample120us  5
#define sample240us  6
#define sample480us  7

/* Create the TOS_ADC_PORT Mapping Table */
#define TOS_ADC_PORT_0 0
#define TOS_ADC_PORT_1 1
#define TOS_ADC_PORT_2 2
#define TOS_ADC_PORT_3 3
#define TOS_ADC_PORT_4 4
#define TOS_ADC_PORT_5 5
#define TOS_ADC_PORT_6 6
#define TOS_ADC_PORT_7 7
#define TOS_ADC_PORT_8 8
#define TOS_ADC_PORT_9 9

#define PORTMAPSIZE 10
extern char PORTMAP[PORTMAPSIZE];

#define ADC_PORTMAP_BIND(tos_port, adc_port)\
PORTMAP[(int)tos_port]=adc_port;
#define ADC_PORTMAP(tos_port)\
PORTMAP[(int)tos_port]

#define VOLTAGE_PORT	30	/* TOS_ADC_PORT_30 */

#ifdef FULLPC

#define TOS_INTERRUPT_HANDLER(name, params) \
void name##_interrupt params 

#define TOS_SIGNAL_HANDLER(signame, params) \
void signame##_signal params

#define TOS_ISSUE_INTERRUPT(name) \
name##_interrupt

#define TOS_ISSUE_SIGNAL(signame) \
signame##_signal

#else

#define TOS_INTERRUPT_HANDLER(name, params) \
INTERRUPT(name)

#define TOS_SIGNAL_HANDLER(signame, params) \
SIGNAL(signame)

#define TOS_ISSUE_INTERRUPT(name)
#define TOS_ISSUE_SIGNAL(signame)


#endif //FULLPC

#endif //__HARDWARE__
