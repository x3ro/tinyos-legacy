/*
 * $Header: /cvsroot/tinyos/tinyos-1.x/contrib/minitasks/03/uva/EnviroTrack/Enviro.nc,v 1.6 2003/06/12 01:02:14 cssharp Exp $
 */

/* "Copyright (c) 2000-2002 University of Virginia.  
 * All rights reserved.
 * 
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF VIRGINIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY OF
 * VIRGINIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF VIRGINIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF VIRGINIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 * 
 * Authors: Brain Blum,Tian He 
 */

includes Enviro;
includes GF;

includes Config;
includes Routing;

configuration Enviro {
}

implementation {
  components Main, GenericComm, LedsC, MagU16C, RandomLFSR, TimedLedsC, UVARoutingC, GFM, RoutingDD;
  components TimerC, TrackingM, ECMM, EMMM, TriangM, LocalM, SysSyncC;
  components RoutingC, ConfigC;
     
//  Main.StdControl -> LogicalTime;    
  Main.StdControl -> TimedLedsC;
  Main.StdControl -> GenericComm;
  Main.StdControl -> MagU16C;
  Main.StdControl -> SysSyncC;
    
  TrackingM.SendMsgByBct -> UVARoutingC.RoutingSendByBroadcast[TRACKING_APP];
  TrackingM.ReceiveBctMsg -> UVARoutingC.RoutingReceive[TRACKING_APP];    
  TrackingM.Random -> RandomLFSR;
  TrackingM.EMM -> EMMM;
  TrackingM.ECM -> ECMM;
  TrackingM.Beacon -> GFM;
  TrackingM.TimedLeds -> TimedLedsC;
  TrackingM.TimedLedsStdCtrl -> TimedLedsC;
  TrackingM.MagneticSensor->MagU16C;
  TrackingM.Triang -> TriangM;
  TrackingM.TrackingTimer -> TimerC.Timer[unique("Timer")]; 
  //LogicalTime.Timer[unique("Timer")];
  TrackingM.GetLeader -> EMMM;
  TrackingM.ADCControl -> MagU16C.StdControl;
  TrackingM.Local -> LocalM.Local;
  TrackingM.SysSync -> SysSyncC.SysSync;  
  TrackingM.NetworkControl -> UVARoutingC.StdControl; 
  TrackingM.DDControl -> RoutingDD.StdControl; 
  TrackingM.Phase1Timer -> TimerC.Timer[unique("Timer")];
  TrackingM.Phase2Timer -> TimerC.Timer[unique("Timer")];
  
  EMMM.SendMsgByBct -> UVARoutingC.RoutingSendByBroadcast[EMMM_APP];
  EMMM.ReceiveRoutingMsg -> UVARoutingC.RoutingReceive[EMMM_APP]; 
  EMMM.Random -> RandomLFSR;
  EMMM.TimedLeds -> TimedLedsC;
  EMMM.TimedLedsStdCtrl ->TimedLedsC;
  EMMM.Local -> LocalM.Local;
  
/*
  ECMM.SendMsgByID -> UVARoutingC.RoutingSendByAddress[ECMM_APP];
  ECMM.ReceiveRoutingMsg -> UVARoutingC.RoutingReceive[ECMM_APP];
*/
  ECMM.SendToUart -> UVARoutingC.RoutingSendByAddress[ECMM_APP];
  ECMM.ReceiveGFRoutingMsg -> UVARoutingC.RoutingReceive[ECMM_APP];
  
  ECMM.SendMsgByID -> RoutingDD.RoutingSendByMobileID;
  ECMM.ReceiveRoutingMsg -> RoutingDD.RoutingDDReceiveDataMsg;
  ECMM.GetLeader -> EMMM;    
  ECMM.TimedLeds -> TimedLedsC;
}
