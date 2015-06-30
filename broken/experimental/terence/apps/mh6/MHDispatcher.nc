/* -*- Mode: C; c-basic-indent: 2; indent-tabs-mode: nil -*- */ 
/* $Id: MHDispatcher.nc,v 1.6 2003/02/27 05:21:17 wetoasis Exp $ */
/*////////////////////////////////////////////////////////*/
/**
 * Author: Terence Tong, Alec Woo
 */
/*////////////////////////////////////////////////////////*/

includes RoutingStackShared;
configuration MHDispatcher {
  provides {
    interface MultiHopSend[uint8_t msgId];
    interface MHSend2Comm;
  }

}

implementation {
  components Main, MHDispatcherM, GenericComm, MHSender, VirtualComm, CrcFilter as Receiver,
    MinTrans as RoutingC, Statistic; // NullRouting as RoutingC; // 
  MultiHopSend = MHDispatcherM.MultiHopSend;
	
  MHSend2Comm = MHDispatcherM.MHSend2Comm;
  MHDispatcherM.VCSend -> VirtualComm.VCSend[RS_DATA_TYPE];
  MHDispatcherM.ReceiveAll -> Receiver.UpperReceive;
  RoutingC.CommNotifier -> MHDispatcherM.CommNotifier;
  MHDispatcherM.RouteHeader -> RoutingC.RouteHeader;
  MHDispatcherM.Originated -> MHSender.OriginatedMsg;
	
  MHSender.ForwardReceive -> MHDispatcherM.ForwardReceive;

  // statistic

  MHDispatcherM.RouteHeader -> Statistic.RouteHeader;
  Statistic.CommNotifier -> MHDispatcherM.CommNotifier;
  Statistic.RouteState -> RoutingC.RouteState;

}
