/* -*- Mode: C; c-basic-indent: 2; indent-tabs-mode: nil -*- */ 
/* $Id: MinTrans.nc,v 1.6 2003/03/07 07:14:32 wetoasis Exp $ */
/*////////////////////////////////////////////////////////*/
/**
 * Author: Alec Woo, Terence Tong
 */
/*////////////////////////////////////////////////////////*/
configuration MinTrans {
  provides {
    interface RouteHeader;
    interface RouteState;
  }
  uses {
    interface CommNotifier;
  }
}

implementation {
  components GenericComm, SimpleMinTransM as MinTransM, Main, RouteHelper, RandomLFSR, TimerWrapper, LedsC, VirtualComm, UARTPacket;
  Main.StdControl -> MinTransM.StdControl;
  RouteHeader = MinTransM.RouteHeader;
  CommNotifier = MinTransM.CommNotifier;
  RouteState = MinTransM.RouteState;
  MinTransM.RouteHelp -> RouteHelper.RouteHelp;
  MinTransM.Timer -> TimerWrapper.Timer[unique("Timer")];
  MinTransM.OffsetTimer -> TimerWrapper.Timer[unique("Timer")];
  MinTransM.Random -> RandomLFSR.Random;
  MinTransM.Leds -> LedsC.Leds;
  MinTransM.MinTransDBPacket -> UARTPacket.MinTransDBPacket;
}

