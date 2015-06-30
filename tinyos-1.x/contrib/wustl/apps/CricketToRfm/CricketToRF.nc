includes CricketToRF;

configuration CricketToRF {
}
implementation {
  components Main, CricketToRFM, SerialM, HPLUARTC, LedsC as LEDs, TimerC;
  components GenericComm;
  
  Main.StdControl -> CricketToRFM;
  Main.StdControl -> TimerC;
  Main.StdControl -> GenericComm;
  
  SerialM.HPLUART -> HPLUARTC;
  SerialM.Leds -> LEDs;  
  
  CricketToRFM.Serial -> SerialM;
  CricketToRFM.Leds -> LEDs;
  CricketToRFM.SendMsg -> GenericComm.SendMsg[AM_CRICKETMSG];
}


