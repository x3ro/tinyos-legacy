/* 
 * ECC Probing application
 */
includes AM;
includes ECC;
includes IntMsg;

configuration ECCProbe
{
}

implementation
{
  components Main, ECCProbeM, TimerC, 
    LedsC, NoLeds, GenericComm as Comm, 
    QueuedSendM as Queue, Attr;
  
  Main.StdControl -> ECCProbeM.StdControl;
  ECCProbeM.Timer -> TimerC.Timer[unique("Timer")];
  ECCProbeM.CommControl -> Comm.Control;
  ECCProbeM.SendMsg -> Queue.QueueSendMsg[AM_INTMSG];
  ECCProbeM.QueueControl -> Queue.StdControl;
  ECCProbeM.ReceiveMsg -> Comm.ReceiveMsg[AM_INTMSG];
  ECCProbeM.Leds -> LedsC;
  ECCProbeM.AttrControl -> Attr.StdControl;
  ECCProbeM.AttrUse -> Attr.AttrUse;
  Queue.SerialSendMsg -> Comm.SendMsg;
  Queue.Leds -> NoLeds;
}

//EOF
