/**
 * Copyright (c) 2005 Hewlett-Packard Company
 * All rights reserved
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met:

 *     * Redistributions of source code must retain the above copyright
 *       notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above
 *       copyright notice, this list of conditions and the following
 *       disclaimer in the documentation and/or other materials provided
 *       with the distribution.
 *     * Neither the name of the Hewlett-Packard Company nor the names of its
 *       contributors may be used to endorse or promote products derived
 *       from this software without specific prior written permission.

 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 * LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 *  Configuration abstraction for AccessPoint
 *
 *  Author: Andrew Christian <andrew.christian@hp.com>
 *          August 2005
 */

configuration AccessPointC {
  provides {
    interface StdControl;
    interface Message;
    interface AccessPoint; 
    interface ParamView;
  }
}
implementation {
#ifdef BEACON_ENABLED
  components BeaconAccessPointM as AccessPointM, 
             LedsC,
#else
  components AccessPointM, 
#endif
    CC2420HighLevelC, 
    TimerC, 
    MessagePoolM, 
    IEEEUtilityM;

  StdControl   = AccessPointM;
  Message      = AccessPointM;
  AccessPoint  = AccessPointM;
  ParamView    = AccessPointM;

  AccessPointM.RadioStdControl -> CC2420HighLevelC;
  AccessPointM.Radio           -> CC2420HighLevelC;
  AccessPointM.CC2420Control   -> CC2420HighLevelC;

  AccessPointM.Timer          -> TimerC.Timer[unique("Timer")];
#ifdef BEACON_ENABLED
  AccessPointM.BeaconTimer    -> TimerC.Timer[unique("Timer")];
  AccessPointM.SuperframeTimer-> TimerC.Timer[unique("Timer")];
  AccessPointM.Leds           -> LedsC;
#endif
  AccessPointM.TimerControl   -> TimerC.StdControl;

  AccessPointM.MessagePool    -> MessagePoolM;
  AccessPointM.IEEEUtility    -> IEEEUtilityM;
}
