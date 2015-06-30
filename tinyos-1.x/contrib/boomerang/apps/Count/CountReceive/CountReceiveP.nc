// $Id: CountReceiveP.nc,v 1.1.1.1 2007/11/05 19:08:58 jpolastre Exp $

/*
 * Copyright (c) 2006 Moteiv Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached MOTEIV-LICENSE     
 * file. If you do not find these files, copies can be found at
 * http://www.moteiv.com/MOTEIV-LICENSE.txt and by emailing info@moteiv.com.
 */

/**
 * CountReceive: Receive the count from the radio and display it on the leds.
 *
 * @author Cory Sharp <info@moteiv.com>
 */

#include "../CountMsg.h"

module CountReceiveP {
  provides interface StdControl;
  uses interface ReceiveMsg;
  uses interface Leds;
}
implementation {
  command result_t StdControl.init() {
    return SUCCESS;
  }

  command result_t StdControl.start() {
    return SUCCESS;
  }

  command result_t StdControl.stop() {
    return SUCCESS;
  }

  event TOS_MsgPtr ReceiveMsg.receive( TOS_MsgPtr msg ) {
    CountMsg_t* body = (CountMsg_t*)msg->data;
    call Leds.set( body->n );
    return msg;
  }
}

