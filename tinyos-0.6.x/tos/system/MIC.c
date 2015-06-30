/*									tab:4
 * MIC.c - TOS abstraction of asynchronous digital photo sensor
 *
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
 * Authors:		Alec Woo
 *
 */

/*  OS component abstraction of the analog photo sensor and */
/*  associated A/D support.  It provides an asynchronous interface */
/*  to the photo sensor. */

/*  MIC_INIT command initializes the device. */
/*  MIC_GET_DATA command initiates acquiring the MIC sensor analog reading. */
/*    It returns immediately.  */
/*  MIC_DATA_READY is signaled, providing data, when it becomes available. */
/*  Access to the sensor is performed in the background by a separate TOS task. */

#include "tos.h"
#include "MIC.h"
#include "sensorboard.h"

/* Command to acquire data through continuous sampling at a rate
   specified at SET_SAMPLING_RATE command. */
char TOS_COMMAND(MIC_GET_CONTINUOUS_DATA)(){
  return TOS_CALL_COMMAND(SUB_ADC_GET_CONTINUOUS_DATA)(TOS_ADC_PORT_8);
}

/* Command to acquire a single sample at a sampling rate
   specified at SET_SAMPLING_RATE command. */
char TOS_COMMAND(MIC_GET_DATA)(){
  return TOS_CALL_COMMAND(SUB_ADC_GET_DATA)(TOS_ADC_PORT_8);
}

/* Note: POT gain should be adjusted during shutdown MIC is on. */

/* Command to initialize this component */
char TOS_COMMAND(MIC_INIT)(){
  ADC_PORTMAP_BIND(TOS_ADC_PORT_8, MIC_PORT);
  MAKE_MIC_CTL_OUTPUT();
  CLR_MIC_CTL_PIN();
  MAKE_MIC_MUX_SEL_OUTPUT();
  CLR_MIC_MUX_SEL_PIN();
  MAKE_TONE_DECODE_SIGNAL_INPUT();
  cbi(EIMSK, INT3);
  return TOS_CALL_COMMAND(SUB_ADC_INIT)() & TOS_CALL_COMMAND(SUB_POT_INIT)();
}

/* Command to power cycle the microhpone */
char TOS_COMMAND(MIC_PWR)(char mode){
  if (mode == 0)
    CLR_MIC_CTL_PIN();
  else
    SET_MIC_CTL_PIN();
  return 1;
}

/* Command to enable or disable microphone interrupt */
char TOS_COMMAND(MIC_TONE_INTR)(char enable){
  if (enable == 0)
    cbi(EIMSK, INT3);
  else
    sbi(EIMSK, INT3);
  return 1;
}

/* Command to select the signal to be acquired from the microphone.
   It's either microhpone voice-band output or tone decodeder's phase
   output.
 */
char TOS_COMMAND(MIC_MUX_SEL)(char select){
  if (select == 0)
    CLR_MIC_MUX_SEL_PIN();
  else
    SET_MIC_MUX_SEL_PIN();
  return 1;
}

/* Command to adjust the gain for the microphone */
char TOS_COMMAND(MIC_POT_ADJUST)(char val){
  return TOS_CALL_COMMAND(SUB_WRITE_POT)(MIC_POT_ADDR, 0, val);
}

/* Handling the acknowledgment of changing the pot setting */
char TOS_EVENT(SUB_WRITE_POT_DONE)(char success){
  return 1;
}

/* Handling the acknowledgment of reading the pot setting */
char TOS_EVENT(SUB_READ_POT_DONE)(char data, char success){
  return 1;
}

/* Sample the tone detector's output */
char TOS_COMMAND(MIC_READ_TONE_DETECTOR)(){
  return READ_TONE_DECODE_SIGNAL_PIN();
}

/* External interrupt on the tone decoder occurs.
   Disable TONE_DETECTED Interrupt and re-enable interrupt
   before signalling the higher level. */
TOS_SIGNAL_HANDLER(SIG_INTERRUPT3, ()){
  cbi(EIMSK, INT3);
  sei();
  TOS_SIGNAL_EVENT(MIC_SIGNAL_TONE_DETECTED)();
}

