/* -*- Mode: C; c-basic-indent: 2; indent-tabs-mode: nil -*- */ 
/* $Id: Statistic.nc,v 1.5 2003/02/27 05:21:17 wetoasis Exp $ */
/*////////////////////////////////////////////////////////*/
/**
 * Author: Terence Tong, Alec Woo
 */
/*////////////////////////////////////////////////////////*/

includes RoutingStackShared;
configuration Statistic {
  provides {
    interface RouteHeader;
  }
  uses {
    interface CommNotifier;
    interface RouteState;
  }

}
implementation {
  components Main, MHDispatcher, TimerWrapper, LedsC, StatisticM, Photo;
  RouteHeader = StatisticM.RouteHeader;
  CommNotifier = StatisticM.CommNotifier;
  RouteState = StatisticM.RouteState;

  Main.StdControl -> StatisticM.StdControl;
  StatisticM.MultiHopSend -> MHDispatcher.MultiHopSend[RS_STATISTIC_INTERNAL_TYPE];
  StatisticM.Leds -> LedsC;
  StatisticM.Timer -> TimerWrapper.Timer[unique("Timer")];
	
  // for the light sensor
  Main.StdControl -> Photo;
  StatisticM.ADC -> Photo;
}
