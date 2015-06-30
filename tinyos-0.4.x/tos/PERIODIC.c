/*									tab{4
 *  
 *
 * "Copyright (c) 2001 and The Regents of the University 
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
 * Authors:  Sam Madden
 * Date:     June, 2001
 *

Component to transmit periodic schema fields out over the
network.

Works by examining the schema for peridic fields,
and if such fields exist, initializing the clock
to allow transmission of fields at the correct period.

Period of periodic transmissions can be set via a 
SET_PERIOD_MESSAGE, the format of which is described
in system/include/period_msg.h

 *
 */

#include "tos.h"
#include "PERIODIC.h"
#include "moteschema.h"
#include "period_msg.h"
#include "SensorQuery.h"

#define TOS_FRAME_TYPE PERIODIC_frame

TOS_FRAME_BEGIN(PERIODIC_frame) {
  char samples[kMAX_FIELDS];
  char seconds[kMAX_FIELDS];  //samplerate == samples / seconds
  int clocks_per_sample[kMAX_FIELDS];
  char pending;
  TOS_Msg msg;
}
TOS_FRAME_END(PERIODIC_frame);


char TOS_COMMAND(INIT_PERIODIC)() {
#ifdef kHAS_SCHEMA
  int i;
  char hasClock = 0;

  VAR(pending) = 0;
  for (i = 0; i < kMAX_FIELDS; i++) {
    if (gMoteSchema.cnt > i && gMoteSchema.fields[i].direction == periodically) {
      VAR(samples)[i] = 1;
      VAR(seconds)[i] = 1;
      hasClock = 1;
      VAR(clocks_per_sample)[i] = 1000;
    } else
      VAR(samples)[i] = 0;
  }
  if (hasClock) {
    TOS_CALL_COMMAND(CLOCK_SUB_INIT)(tick1000ps);
  }
  VAR(pending) = 0;
#endif
    return 1;
}

TOS_MsgPtr TOS_EVENT(SET_PERIOD_MSG)(TOS_MsgPtr msg) {
#ifdef kHAS_SCHEMA
  period_msg *msg_data = (period_msg *)(msg->data);
  int sid = msg_data->sensorId;
  if (gMoteSchema.cnt > sid && //is a valid field ?
      VAR(samples)[sid]) {     //is a periodic field ?
    VAR(seconds)[sid] = msg_data->seconds;
    VAR(samples)[sid] = msg_data->samples;
    VAR(clocks_per_sample)[sid] = ((1000) * (int)msg_data->seconds) / (int)msg_data->samples;
  }  
#endif
  return msg;
}

void TOS_EVENT(CLOCK_SIGNAL)(void) {
#ifdef kHAS_SCHEMA
  int i;
  sensor_msg *out_msg = (sensor_msg *)(&(VAR(msg).data));

  if (VAR(pending)) return;

  for (i = 0; i < gMoteSchema.cnt; i++) {
    if ( VAR(samples)[i] &&     //is a periodic field ?
	 (-- VAR(clocks_per_sample)[i]) <= 0) { //is ready to xmit?
      VAR(clocks_per_sample)[i] = ((1000) * (int)VAR(seconds)[i]) / ((int)VAR(samples)[i]);
      out_msg->src = TOS_LOCAL_ADDRESS;
      out_msg->fieldId = i;
      TOS_SIGNAL_EVENT(PERIODIC_SENSOR_QUERY)(&VAR(msg)); //only send one message per clock tick, max 
      //this means a sensor sampling at the clock frequency will starve other sensors from 
      //being periodic -- oh well... 
    }  
  }
#endif
}

char TOS_EVENT(SUB_MSG_SEND_DONE)(TOS_MsgPtr msg) {
  if (msg == &VAR(msg))
    VAR(pending) = 0;
  return 1;
}

