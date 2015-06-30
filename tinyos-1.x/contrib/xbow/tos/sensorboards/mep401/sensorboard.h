/*									tab:4
 * "Copyright (c) 2000-2003 The Regents of the University  of California.  
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
 * Copyright (c) 2002-2003 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */
/*
 *
 * Authors:		Joe Polastre
 *
 * $Id: sensorboard.h,v 1.7 2004/07/16 21:55:54 ammbot Exp $
 */

// These are the settings for the U1 (external) humidity sensor
#define HUMIDITY_POWER_ON()          { TOSH_MAKE_PW2_OUTPUT(); TOSH_SET_PW2_PIN(); }
#define HUMIDITY_POWER_OFF()         TOSH_CLR_PW2_PIN();

#define HUMIDITY_INT_ENABLE()        sbi(EIMSK , 4)
#define HUMIDITY_INT_DISABLE()       cbi(EIMSK , 4)
#define HUMIDITY_INTERRUPT           SIG_INTERRUPT4

#define HUMIDITY_MAKE_CLOCK_OUTPUT() TOSH_MAKE_PW5_OUTPUT()  //sbi(DDRC, 3)
#define HUMIDITY_MAKE_CLOCK_INPUT()  TOSH_MAKE_PW5_INPUT()   //sbi(DDRC, 3)
#define HUMIDITY_SET_CLOCK()         TOSH_SET_PW5_PIN()      // sbi(PORTC, 3)
#define HUMIDITY_CLEAR_CLOCK()       TOSH_CLR_PW5_PIN()      // cbi(PORTC, 3)

#define HUMIDITY_SET_DATA()          TOSH_SET_INT0_PIN()     // sbi(PORTD, 3)
#define HUMIDITY_CLEAR_DATA()        TOSH_CLR_INT0_PIN()     // cbi(PORTD, 3)
#define HUMIDITY_MAKE_DATA_OUTPUT()  TOSH_MAKE_INT0_OUTPUT() // sbi(DDRD, 3)
#define HUMIDITY_MAKE_DATA_INPUT()   TOSH_MAKE_INT0_INPUT()  // cbi(DDRD, 3)
#define HUMIDITY_GET_DATA()          TOSH_READ_INT0_PIN()    // (inp(PIND) >> 3) & 0x1


// These are the settings for the U2 (internal) humidity sensor
#define INTHUMIDITY_POWER_ON()          { TOSH_MAKE_PW4_OUTPUT(); TOSH_SET_PW4_PIN(); }
#define INTHUMIDITY_POWER_OFF()         TOSH_CLR_PW4_PIN();

#define INTHUMIDITY_INT_ENABLE()        sbi(EIMSK , 5)
#define INTHUMIDITY_INT_DISABLE()       cbi(EIMSK , 5)
#define INTHUMIDITY_INTERRUPT           SIG_INTERRUPT5

#define INTHUMIDITY_MAKE_CLOCK_OUTPUT() TOSH_MAKE_PW7_OUTPUT()  //sbi(DDRC, 3)
#define INTHUMIDITY_MAKE_CLOCK_INPUT()  TOSH_MAKE_PW7_INPUT()   //sbi(DDRC, 3)
#define INTHUMIDITY_SET_CLOCK()         TOSH_SET_PW7_PIN()      // sbi(PORTC, 3)
#define INTHUMIDITY_CLEAR_CLOCK()       TOSH_CLR_PW7_PIN()      // cbi(PORTC, 3)

#define INTHUMIDITY_SET_DATA()          TOSH_SET_INT1_PIN()     // sbi(PORTD, 3)
#define INTHUMIDITY_CLEAR_DATA()        TOSH_CLR_INT1_PIN()     // cbi(PORTD, 3)
#define INTHUMIDITY_MAKE_DATA_OUTPUT()  TOSH_MAKE_INT1_OUTPUT() // sbi(DDRD, 3)
#define INTHUMIDITY_MAKE_DATA_INPUT()   TOSH_MAKE_INT1_INPUT()  // cbi(DDRD, 3)
#define INTHUMIDITY_GET_DATA()          TOSH_READ_INT1_PIN()    // (inp(PIND) >> 3) & 0x1

#define HUMIDITY_TIMEOUT_MS          30
#define HUMIDITY_TIMEOUT_TRIES       20

// Added MEP401 TOSH pin mappings [2004/6/23] -mturon 
TOSH_ASSIGN_PIN(PWM0,   B, 4);
TOSH_ASSIGN_PIN(PWM1A,  B, 6);
TOSH_ASSIGN_PIN(PWM1B,  B, 5);

// New MEP401 mappings
#define PRESSURE_SET_CLOCK()           TOSH_SET_PWM0_PIN()
#define PRESSURE_CLEAR_CLOCK()         TOSH_CLR_PWM0_PIN()
#define PRESSURE_MAKE_CLOCK_OUTPUT()   TOSH_MAKE_PWM0_OUTPUT() //asm volatile ("nop" ::)

#define PRESSURE_MAKE_IN_INPUT()       TOSH_MAKE_PWM1A_INPUT()
#define PRESSURE_READ_IN_PIN()         TOSH_READ_PWM1A_PIN()
#define PRESSURE_SET_IN_PIN()          TOSH_SET_PWM1A_PIN()
#define PRESSURE_CLEAR_IN_PIN()        TOSH_CLR_PWM1A_PIN()

#define PRESSURE_MAKE_OUT_OUTPUT()     TOSH_MAKE_PWM1B_OUTPUT()
#define PRESSURE_SET_OUT_PIN()         TOSH_SET_PWM1B_PIN()
#define PRESSURE_CLEAR_OUT_PIN()       TOSH_CLR_PWM1B_PIN()
#define PRESSURE_TIMEOUT_TRIES         5

#define PRESSURE_POWER_ON()            { TOSH_MAKE_PW3_OUTPUT(); TOSH_SET_PW3_PIN(); }
#define PRESSURE_POWER_OFF()           TOSH_CLR_PW3_PIN()

#define ACCEL_POWER_ON()          { TOSH_MAKE_PW6_OUTPUT(); TOSH_SET_PW6_PIN(); }
#define ACCEL_POWER_OFF()         TOSH_CLR_PW6_PIN();

enum {
  ACCELX_ADC_PORT = 6,
  ACCELY_ADC_PORT = 1
};

enum {
  HAMAMATSU_ADC_TOPPAR = 5,
  HAMAMATSU_ADC_TOPBS = 3,
  HAMAMATSU_ADC_BOTPAR = 4,
  HAMAMATSU_ADC_BOTBS = 2
};

enum {
  HAMAMATSU1_ADC_PORT = 5,
  HAMAMATSU2_ADC_PORT = 3,
  HAMAMATSU3_ADC_PORT = 4,
  HAMAMATSU4_ADC_PORT = 2
};

enum {
  // Internal Sensirion Humidity addresses and commands
  TOSH_HUMIDITY_ADDR = 5,
  TOSH_HUMIDTEMP_ADDR = 3,
  TOSH_HUMIDITY_RESET = 0x1E,
};

// External Sensirion Humidity addresses and commands
enum {  
  TOSH_INTHUMIDITY_ADDR = 5,
  TOSH_INTHUMIDTEMP_ADDR = 3,
  TOSH_INTHUMIDITY_RESET = 0x1E
};
