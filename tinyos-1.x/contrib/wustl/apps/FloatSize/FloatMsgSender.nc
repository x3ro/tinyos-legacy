// $Id: FloatMsgSender.nc,v 1.1 2007/04/05 07:58:05 chien-liang Exp $

includes FloatMsg;

configuration FloatMsgSender { }
implementation
{
  components Main, FloatMsgSenderM
           , TimerC
           , LedsC
           , GenericComm as Comm;

  Main.StdControl -> FloatMsgSenderM;
  Main.StdControl -> TimerC;
  
  FloatMsgSenderM.Timer -> TimerC.Timer[unique("Timer")];
  FloatMsgSenderM.Leds -> LedsC;
  FloatMsgSenderM.CommControl -> Comm;
  FloatMsgSenderM.DataMsg -> Comm.SendMsg[AM_FLOATMSG];
}
