// $Id: Surge.nc,v 1.2 2005/01/22 01:51:42 mturon Exp $

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
/**
 * 
 **/
#include "appFeatures.h"

includes Surge;
includes SurgeCmd;
includes MultiHop;

configuration Surge {
}
implementation {
  components Main, SurgeM, TimerC, LedsC, NoLeds, ADCC, RandomLFSR, PhotoTemp,
      GenericCommPromiscuous as Comm, Bcast, 
      MULTIHOPROUTER as multihopM , QueuedSend, 
      XEE_PARAMS_COMPONENT
      DELUGE_COMPONENT
      TRACK_POWER_COMPONENT
      Sounder, Accel, AttrMag, Attr
      ;

  // Main.StdControl -> DelugeC;
  Main.StdControl -> SurgeM.StdControl;
  Main.StdControl -> Bcast.StdControl;
  Main.StdControl -> multihopM.StdControl;
  Main.StdControl -> QueuedSend.StdControl;
  Main.StdControl -> TimerC;
  Main.StdControl -> Comm;
  Main.StdControl -> AttrMag;
  //  multihopM.CommControl -> Comm; 

  DELUGE_WIRING()
  XEE_PARAMS_WIRING()

  SurgeM.ADCControl -> ADCC;
  SurgeM.Batt   -> ADCC.ADC[TOS_ADC_BANDGAP_PORT];
  SurgeM.Temp   -> PhotoTemp.ExternalTempADC;
  SurgeM.AccelX   -> Accel.AccelX;
  SurgeM.AccelY   -> Accel.AccelY;
  SurgeM.AccelCtl   -> Accel;
  SurgeM.Light   -> PhotoTemp.ExternalPhotoADC;
  SurgeM.TempStdControl   -> PhotoTemp.TempStdControl;
  SurgeM.LightStdControl   -> PhotoTemp.PhotoStdControl;
  SurgeM.TempTimer -> TimerC.Timer[unique("Timer")];
  SurgeM.Timer -> TimerC.Timer[unique("Timer")];
  SurgeM.Leds  -> LedsC; // NoLeds;
  SurgeM.Sounder -> Sounder;
  SurgeM.AttrUse -> Attr.AttrUse;
#if FEATURE_TRACK_POWER
  SurgeM.GetPower -> CC1000RadioIntM.GetPower;
  SurgeM.GetPower_send -> CC1000RadioIntM.GetPower_send;
  SurgeM.GetPower_receive -> CC1000RadioIntM.GetPower_receive;
  SurgeM.GetPower_check -> CC1000RadioIntM.GetPower_check;
  SurgeM.GetPower_total_sum -> CC1000RadioIntM.GetPower_total_sum;
  SurgeM.GetSendCount -> CC1000RadioIntM.GetSendCount;
#endif

  SurgeM.Bcast -> Bcast.Receive[AM_SURGECMDMSG];
  Bcast.ReceiveMsg[AM_SURGECMDMSG] -> Comm.ReceiveMsg[AM_SURGECMDMSG];

  SurgeM.RouteControl -> multihopM;
  SurgeM.Send -> multihopM.Send[AM_SURGEMSG];
  multihopM.ReceiveMsg[AM_SURGEMSG] -> Comm.ReceiveMsg[AM_SURGEMSG];
  //multihopM.ReceiveMsg[AM_MULTIHOPMSG] -> Comm.ReceiveMsg[AM_MULTIHOPMSG];
}



