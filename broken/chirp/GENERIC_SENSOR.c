/*
 * @(#)COMMAND.c
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
 * Author:  Kamin Whitehouse
 * History: Created 2/10/02
 *
 * This component is meant to be a generic passive sensor node.  It doesn't
 * do anything until told but it can do almost all the functions that a sensor
 * node should be able to do.
 * 
 * $\Id$
 */

#include "tos.h"
#include "GENERIC_SENSOR.h"


#define TOS_FRAME_TYPE GENERIC_SENSOR_obj_frame
TOS_FRAME_BEGIN(GENERIC_SENSOR_obj_frame) {
  TOS_MsgPtr msg;
  char send_pending;
}
TOS_FRAME_END(GENERIC_SENSOR_obj_frame);



char TOS_COMMAND(GENERIC_SENSOR_INIT) () {
    TOS_CALL_COMMAND(GENERIC_SENSOR_SUB_INIT)();
    VAR(send_pending) = 0;
    return 1;
}

char TOS_COMMAND(GENERIC_SENSOR_START)(){
    return 1;
}



