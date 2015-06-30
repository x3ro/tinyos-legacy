/* -*- Mode: C; c-basic-indent: 2; indent-tabs-mode: nil -*- */ 
/* $Id: RouteHelper.nc,v 1.9 2003/04/02 10:39:54 wetoasis Exp $ */
/*////////////////////////////////////////////////////////*/
/**
 * Author: Terence Tong, Alec Woo
 */
/*////////////////////////////////////////////////////////*/

configuration RouteHelper {
  provides {
    interface RouteHelp;
  }
}

implementation {
  components Main, RouteHelperM, VirtualComm, RandomLFSR, Wmewma as Est; 
  RouteHelp = RouteHelperM.RouteHelp;
  RouteHelperM.Estimator -> Est.Estimator;
  RouteHelperM.VCSend -> VirtualComm.VCSend[RS_ROUTE_TYPE];
  RouteHelperM.RouteReceive ->VirtualComm.ReceiveMsg[RS_ROUTE_TYPE];
  Main.StdControl -> RouteHelperM.StdControl;
  RouteHelperM.TablePacketSend -> VirtualComm.VCSend[RS_TABLE_PACKET_TYPE];
  // RouteHelperM.Random -> RandomLFSR.Random;
}
