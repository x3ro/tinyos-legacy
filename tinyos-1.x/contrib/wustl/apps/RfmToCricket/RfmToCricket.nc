includes CricketToRF;

configuration RfmToCricket {
}
implementation {
  components Main, RfmToCricketM, TimerC, LedsC, UART;  
  components GenericComm;
  
  Main.StdControl -> RfmToCricketM;
  Main.StdControl -> TimerC;
  Main.StdControl -> UART;
  Main.StdControl -> GenericComm;
  
  RfmToCricketM.ReceiveMsg -> GenericComm.ReceiveMsg[AM_CRICKETMSG];
  RfmToCricketM.Leds -> LedsC;
  RfmToCricketM.ByteComm -> UART;
}

