/**
 *
 * This is an auxiliary program for MNP. The purpose is to send "reboot" signal after reprogramming is done.
 * 
 * Authors: Limin Wang, Sandeep Kulkarni
 * 
 **/

#define AM_MnpMsg_ID  47

configuration Reboot {
}
implementation {
  components Main, RebootM, TimerC, GenericComm, LedsC;
  Main.StdControl -> RebootM.StdControl;
  RebootM.SendMsg    -> GenericComm.SendMsg[AM_MnpMsg_ID];  
  RebootM.GenericCommCtl -> GenericComm;
  RebootM.Timer -> TimerC.Timer[unique("Timer")];
  RebootM.Leds -> LedsC;
}

