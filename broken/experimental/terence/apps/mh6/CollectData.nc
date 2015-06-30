/* -*- Mode: C; c-basic-indent: 2; indent-tabs-mode: nil -*- */ 
/* $Id: CollectData.nc,v 1.5 2003/03/04 23:43:59 wetoasis Exp $ */
/*////////////////////////////////////////////////////////*/
/**
 * Author: Terence Tong, Alec Woo
 */
/*////////////////////////////////////////////////////////*/

configuration CollectData {
  
}


implementation {
  components Main, CollectDataM, MHDispatcher, TimerWrapper, LedsC, BcastCommand;
  Main.StdControl -> CollectDataM.StdControl;
  CollectDataM.MultiHopSend -> MHDispatcher.MultiHopSend[unique("MHDispathcer")];
  CollectDataM.Timer -> TimerWrapper.Timer[unique("Timer")];
  CollectDataM.Leds -> LedsC;
  CollectDataM.HandleBcast -> BcastCommand.HandleBcast;
}
