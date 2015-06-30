/*
 * Copyright (c) 2006 Moteiv Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached MOTEIV-LICENSE     
 * file. If you do not find these files, copies can be found at
 * http://www.moteiv.com/MOTEIV-LICENSE.txt and by emailing info@moteiv.com.
 */
#include "RemoteControl.h"

/**
 * An application that allows a mote to act as a RemoteControl for a 
 * PowerPoint application.  See the README.RemoteControl document for
 * more details.
 *
 * @author Joe Polastre <info@moteiv.com>
 */
configuration RemoteControl {
}
implementation {
  components Main
    , RemoteControlP as Impl
    , SPC
    , UserButtonAdvancedC
    , LedsC
    ;

  Main.StdControl -> Impl;
  Impl.SPSend -> SPC.SPSend[AM_REMOTECONTROLMSG];
  Impl.ButtonAdvanced -> UserButtonAdvancedC;
  Impl.Leds -> LedsC;
}
