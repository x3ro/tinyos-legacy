/*									tab:4
 * MAG.c - TOS abstraction of asynchronous digital accelerometer
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
 * Authors:		Alec Woo
 *  modified: DEC 10/4/2000 function commented
 *
 */

/*  OS component abstraction of the analog magnetometer sensor and */
/*  associated A/D support.  It provides an asynchronous interface */
/*  to the photo sensor. */

/*  TEMP_INIT command initializes the device */
/*  TEMP_GET_DATA command initiates acquiring a sensor reading. */
/*  It returns immediately.   */
/*  TEMP_DATA_READY is signaled, providing data, when it becomes */
/*  available. */
/*  Access to the sensor is performed in the background by a separate */
/* TOS task. */

#include "tos.h"
#include "MAG.h"
#include "sensorboard.h"

#define TOS_FRAME_TYPE MAG_frame
TOS_FRAME_BEGIN(MAG_frame) 
{
  char state;
  char pot;
}
TOS_FRAME_END(MAG_frame);

char TOS_COMMAND(MAG_GET_XDATA)(){
  return TOS_CALL_COMMAND(MAG_SUB_ADC_GET_DATA)(TOS_ADC_PORT_6);
}

char TOS_COMMAND(MAG_GET_YDATA)(){
  return TOS_CALL_COMMAND(MAG_SUB_ADC_GET_DATA)(TOS_ADC_PORT_8);
}

char TOS_COMMAND(MAG_INIT)(){
  VAR(state) = 0;
  ADC_PORTMAP_BIND(TOS_ADC_PORT_6, MAG_X);
  ADC_PORTMAP_BIND(TOS_ADC_PORT_8, MAG_Y);
  MAKE_MAG_CTL_OUTPUT();
  SET_MAG_CTL_PIN();
  return TOS_CALL_COMMAND(MAG_SUB_ADC_INIT)() & TOS_CALL_COMMAND(MAG_SUB_POT_INIT)();
}

char TOS_COMMAND(MAG_PWR)(char val){
  CLR_MAG_CTL_PIN();
  return 1;
}
 
char TOS_COMMAND(MAG_SET_POT_X)(char val){
  if (VAR(state) == 0){
    VAR(pot) = 1;
    return TOS_CALL_COMMAND(MAG_SUB_WRITE_POT)(MAG_POT_ADDR,VAR(pot),val);
  }
  return 0;
}

char TOS_COMMAND(MAG_SET_POT_Y)(char val){
  if (VAR(state) == 0){
    VAR(pot) = 0;
    return TOS_CALL_COMMAND(MAG_SUB_WRITE_POT)(MAG_POT_ADDR,VAR(pot),val);
  }
  return 0;
}

char TOS_EVENT(MAG_SET_POT_DONE)(char success){
  VAR(state) = 0;
  if (VAR(pot) == 1)
    TOS_SIGNAL_EVENT(MAG_SET_POT_X_DONE)(success);
  else
    TOS_SIGNAL_EVENT(MAG_SET_POT_Y_DONE)(success);
  return 1;
}

char TOS_EVENT(MAG_READ_POT_DONE)(char val, char success){
  return 1;
}
