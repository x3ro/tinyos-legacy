/*									tab:4
 *
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
 * Authors:	        Joe Polastre
 *
 *
 */

#include "tos.h"
#include "MICAWB_ANALOG.h"
#include "dbg.h"

// state of the world
#define IDLE                  10
#define GET_SAMPLE_SWITCH     11
#define GET_SAMPLE_SWITCH_2   14
#define GET_SAMPLE_START      12
#define GET_SAMPLE_DONE       13

// define which sensor to read
#define PHOTO             0x01
#define THERMOPILE        0x02
#define THERMISTOR        0x04
#define HUMIDITY          0x08

#define TOS_FRAME_TYPE ANALOG_obj_frame
TOS_FRAME_BEGIN(ANALOG_obj_frame) {
  char sw_addr;
  char adc_addr;
  char state;
  char sensor;
  char sensors;
}
TOS_FRAME_END(ANALOG_obj_frame);


TOS_TASK(ANALOG_get_sensors){
  // figure out which sensors to read from
  if (VAR(state) == GET_SAMPLE_START)
  {
    if ((VAR(sensors) & PHOTO))
    {
      VAR(sensors) = VAR(sensors) & (255 - PHOTO);
      VAR(sensor) = PHOTO;
      TOS_CALL_COMMAND(ANALOG_GET_SAMPLE)(VAR(adc_addr), 0);
    }
    else if ((VAR(sensors) & HUMIDITY))
    {
      VAR(sensors) = VAR(sensors) & (255 - HUMIDITY);
      VAR(sensor) = HUMIDITY;
      TOS_CALL_COMMAND(ANALOG_GET_SAMPLE)(VAR(adc_addr), 3);
    } 
    else if ((VAR(sensors) & THERMOPILE))
    {
      VAR(sensors) = VAR(sensors) & (255 - THERMOPILE);
      VAR(sensor) = THERMOPILE;
      TOS_CALL_COMMAND(ANALOG_GET_SAMPLE)(VAR(adc_addr), 1);
    }
    else if ((VAR(sensors) & THERMISTOR))
    {
      VAR(sensors) = VAR(sensors) & (255 - THERMISTOR);
      VAR(sensor) = THERMISTOR;
      TOS_CALL_COMMAND(ANALOG_GET_SAMPLE)(VAR(adc_addr), 2);
    }
    else
    {
      VAR(state) = IDLE;
    }
  }
  else
  {
    VAR(state) = IDLE;
  }
}

char TOS_COMMAND(ANALOG_INIT)()
{
  VAR(state) = IDLE;
  VAR(sensor) = 0;
  VAR(sensors) = 0;
  VAR(sw_addr)  = 73; /** 10010 01 **/
  VAR(adc_addr) = 72; /** 10010 00 **/
  return TOS_CALL_COMMAND(ANALOG_SUB_INIT)();
}

// returns the current voltage value of the photo sensor in
// an asymmetric event
char TOS_COMMAND(ANALOG_GET_READING)(char sensors)
{
  if (VAR(state) == IDLE)
  {
    VAR(state) = GET_SAMPLE_START;
    VAR(sensors) = sensors;

    TOS_CALL_COMMAND(ANALOG_SET_SWITCH_ALL)(73,0x04);
    //TOS_CALL_COMMAND(GREEN_LED_TOGGLE)();
    
    return 1;
  }
  else
  {
    return 0;
  }
}


char TOS_EVENT(ANALOG_GET_SAMPLE_DONE)(short value)
{
  //TOS_CALL_COMMAND(YELLOW_LED_TOGGLE)();
  TOS_SIGNAL_EVENT(ANALOG_GET_READING_DONE)(VAR(sensor), value);
  TOS_POST_TASK(ANALOG_get_sensors);

  return 1;
}

char TOS_EVENT(ANALOG_SET_SWITCH_ALL_DONE)(char success)
{
  // TOS_CALL_COMMAND(RED_LED_TOGGLE)();
  TOS_POST_TASK(ANALOG_get_sensors);

  /** if (success == 0)
  {
    VAR(state) = IDLE;
    VAR(status) = 0;
    return 0;
  }
  if (VAR(state) == GET_SAMPLE_SWITCH)
  {
    return 1;
  }
  if (VAR(state) == GET_SAMPLE_SWITCH_2)
  {
    // read the ADC
    VAR(state) = GET_SAMPLE_START;
    TOS_CALL_COMMAND(ANALOG_GET_SAMPLE)(VAR(adc_addr), 0);
    //VAR(state) = IDLE;
  }
  if (VAR(state) == GET_SAMPLE_DONE)
  {
    VAR(state) = IDLE;
  }
  **/

  return success;
}

char TOS_EVENT(ANALOG_SET_SWITCH_DONE)(char success)
{
  return success;
}

char TOS_EVENT(ANALOG_GET_SWITCH_DONE)(char value)
{
  return 1;
}

char TOS_EVENT(ANALOG_GET_SAMPLES_DONE)(short* value, char length)
{
  return 1;
}
