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
#include "MICAWB_PHOTO.h"
#include "dbg.h"

#define IDLE              10
#define GET_SAMPLE_SWITCH 11
#define GET_SAMPLE_SWITCH_2 14
#define GET_SAMPLE_START  12
#define GET_SAMPLE_DONE   13

#define PHOTO 1
#define THERMOPILE 2
#define THERMISTOR 3
#define HUMIDITY 4
#define TEMP 5

#define TOS_FRAME_TYPE PHOTO_obj_frame
TOS_FRAME_BEGIN(PHOTO_obj_frame) {
  char sw_addr;
  char adc_addr;
  char state;
  char status;
  char sensor;
}
TOS_FRAME_END(PHOTO_obj_frame);

char TOS_COMMAND(PHOTO_INIT)()
{
  VAR(status) = 0;
  VAR(state) = IDLE;
  VAR(sw_addr)  = 73; /** 10010 01 **/
  VAR(adc_addr) = 72; /** 10010 00 **/
  return TOS_CALL_COMMAND(PHOTO_SUB_INIT)();
}

// returns the current voltage value of the photo sensor in
// an asymmetric event
char TOS_COMMAND(PHOTO_EXT_SET_SWITCH_ALL)(char value)
{

  VAR(state) = GET_SAMPLE_SWITCH_2;

  return TOS_CALL_COMMAND(PHOTO_SET_SWITCH_ALL)(VAR(sw_addr), value);

  /**
  // turn the light sensor on
  if (VAR(sensor) == PHOTO) 
  {
    return TOS_CALL_COMMAND(PHOTO_SET_SWITCH_ALL)(VAR(sw_addr),0x84);
  }
  else if ((VAR(sensor) == THERMOPILE) || (VAR(sensor) == THERMISTOR))
  {
    return TOS_CALL_COMMAND(PHOTO_SET_SWITCH_ALL)(VAR(sw_addr),0x88);
  }
  else if (VAR(sensor) == HUMIDITY)
  {
    return TOS_CALL_COMMAND(PHOTO_SET_SWITCH_ALL)(VAR(sw_addr),0xA0);
  }
  else if (VAR(sensor) == TEMP)
  {
    return TOS_CALL_COMMAND(PHOTO_SET_SWITCH_ALL)(VAR(sw_addr),0x40);
  } 
  else
  {
    VAR(state) == IDLE;
  }
  **/

  //return 1;
}


char TOS_EVENT(PHOTO_GET_SAMPLE_DONE)(short value)
{
  if (VAR(state) == GET_SAMPLE_START)
  {
    VAR(state) = IDLE;
    TOS_SIGNAL_EVENT(PHOTO_GET_READING_DONE)(VAR(sensor), value);
  }

  return 1;
}

char TOS_EVENT(PHOTO_SET_SWITCH_ALL_DONE)(char success)
{
  if (VAR(state) == GET_SAMPLE_SWITCH_2)
  {
    VAR(state) = IDLE;
    TOS_SIGNAL_EVENT(PHOTO_EXT_SET_SWITCH_ALL_DONE)(success);
  }
  return 1;
}

char TOS_COMMAND(PHOTO_GET_READING)(char sensor)
{
  if (VAR(state) == IDLE)
  {
    VAR(sensor) = sensor;
    // read the ADC
    VAR(state) = GET_SAMPLE_START;
    if (VAR(sensor) == PHOTO)
      TOS_CALL_COMMAND(PHOTO_GET_SAMPLE)(VAR(adc_addr), 0);
    else if (VAR(sensor) == THERMOPILE)
      TOS_CALL_COMMAND(PHOTO_GET_SAMPLE)(VAR(adc_addr), 1);
    else if (VAR(sensor) == THERMISTOR)
      TOS_CALL_COMMAND(PHOTO_GET_SAMPLE)(VAR(adc_addr), 2);
    else if (VAR(sensor) == HUMIDITY)
      TOS_CALL_COMMAND(PHOTO_GET_SAMPLE)(VAR(adc_addr), 3);
    else if (VAR(sensor) == TEMP)
      TOS_CALL_COMMAND(PHOTO_I2CTEMP_GET_SAMPLE)();
    //VAR(state) = IDLE;
  }

  return 1;
}

char TOS_EVENT(PHOTO_SET_SWITCH_DONE)(char success)
{
  return success;
}

char TOS_EVENT(PHOTO_GET_SWITCH_DONE)(char value)
{
  return 1;
}

char TOS_EVENT(PHOTO_GET_SAMPLES_DONE)(short* value, char length)
{
  return 1;
}
