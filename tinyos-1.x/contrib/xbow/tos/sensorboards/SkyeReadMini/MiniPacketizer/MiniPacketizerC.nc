/*
 *
 * Systemic Realtime Design, LLC.
 * http://www.sysrtime.com
 *
 * Authors:  Michael Li
 *
 * Date last modified:  9/30/04
 *
 */


includes MiniPacketizer;

configuration MiniPacketizerC 
{
  provides
  {
    interface StdControl;
    interface MiniPacketizer;
  }
}

implementation 
{
  components MiniPacketizerM, GenericComm as Comm, TimerC; 

  StdControl = MiniPacketizerM;
  StdControl = Comm;
  MiniPacketizer = MiniPacketizerM;

  MiniPacketizerM.SendPacket -> Comm.SendMsg[AMTYPE_MINI];
  MiniPacketizerM.ReceivePacket -> Comm.ReceiveMsg[AMTYPE_MINI];

  MiniPacketizerM.CommCtrl -> Comm;

#ifdef POWER_DOWN_RADIO
  MiniPacketizerM.Sleep -> TimerC.Timer[unique("Timer")]; 
#endif
}
