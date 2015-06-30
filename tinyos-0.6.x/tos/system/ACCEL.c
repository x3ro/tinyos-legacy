/*									tab:4
 * ACCEL.c - TOS abstraction of asynchronous digital accelerometer
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

/*  OS component abstraction of the analog photo sensor and */
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
#include "ACCEL.h"
#include "sensorboard.h"

char TOS_COMMAND(ACCEL_GET_XDATA)(){
    return TOS_CALL_COMMAND(ACCEL_SUB_ADC_GET_DATA)(TOS_ADC_PORT_4);
}

char TOS_COMMAND(ACCEL_GET_YDATA)(){
    return TOS_CALL_COMMAND(ACCEL_SUB_ADC_GET_DATA)(TOS_ADC_PORT_5);
}

char TOS_COMMAND(ACCEL_INIT)(){
  ADC_PORTMAP_BIND(TOS_ADC_PORT_4, ACCEL_X);
  ADC_PORTMAP_BIND(TOS_ADC_PORT_5, ACCEL_Y);
  MAKE_ACCEL_CTL_OUTPUT();
  SET_ACCEL_CTL_PIN();
  return TOS_CALL_COMMAND(ACCEL_SUB_ADC_INIT)();
}

char TOS_COMMAND(ACCEL_PWR)(char val){
  CLR_ACCEL_CTL_PIN();
  return 1;
}
 
