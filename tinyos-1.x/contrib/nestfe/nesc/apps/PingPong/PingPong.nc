includes PingPong;
configuration PingPong
{
}
implementation
{
  components Main,
    NoLeds as LedsC,
    GenericComm as Comm,
    PingPongM,
    KrakenC;

    Main.StdControl -> KrakenC;
    Main.StdControl -> Comm;
    Main.StdControl -> PingPongM;

    PingPongM.Leds -> LedsC;
    PingPongM.ReceiveCmd -> Comm.ReceiveMsg[AM_PPCMDMSG];
    PingPongM.SendReply -> Comm.SendMsg[AM_PPREPLYMSG];
}

