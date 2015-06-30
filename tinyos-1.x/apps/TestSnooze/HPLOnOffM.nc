// $Id: HPLOnOffM.nc,v 1.2 2003/10/07 21:45:22 idgay Exp $

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
 * $Id: HPLOnOffM.nc,v 1.2 2003/10/07 21:45:22 idgay Exp $
 *
 */

includes onoff;

module HPLOnOffM
{
  provides {
    interface OnOff;
  }
  uses {
    interface ReceiveMsg;
    command result_t SetListeningMode(uint8_t power);
    command uint8_t GetListeningMode();
  }
}

implementation
{

  bool newmode;
  OnOff_Msg* onoffmsg;

  task void turnOff() {
    result_t retval = signal OnOff.requestOff();
    if (retval == SUCCESS)
      call OnOff.off();
  }

  task void turnOn() {
    result_t result;
    uint8_t prev_state = call GetListeningMode();

    if (prev_state == 0) {
	signal OnOff.on();
        return;
    }

    if (call SetListeningMode(0)) {
      result = signal OnOff.on();
      if (!result)
        call SetListeningMode(prev_state);
    }
  }
  
  command result_t OnOff.off() {
    result_t retval = call SetListeningMode(CC1K_LPL_STATES-1);
    if (retval)
      newmode = FALSE;
    return retval;
  }

  event TOS_MsgPtr ReceiveMsg.receive(TOS_MsgPtr m) {
    onoffmsg = (OnOff_Msg*)m->data;
    if (onoffmsg->action) {
      newmode = TRUE;
      post turnOn();
    }
    else {
      post turnOff();
    }
    return m;
  }

}
