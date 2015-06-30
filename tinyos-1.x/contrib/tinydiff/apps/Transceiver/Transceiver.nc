configuration Transceiver {
}
implementation {
  components Main,
    TransceiverM,
    RadioCRCPacket as Comm, 
    UARTHostMotePacket as UARTPacket,
#ifndef TOSH_HARDWARE_MICA2
    PotC as Pot,
#else
    CC1000ControlM,
#endif
    Photo,
    Temp,
    ClockC as Clock,
    LedsC as Leds;

  Main.StdControl -> TransceiverM;

  TransceiverM.RadioControl -> Comm.Control;
  TransceiverM.RadioSend -> Comm;
  TransceiverM.RadioReceive -> Comm;

//  TransceiverM.Promiscuous -> Comm.Promiscuous;

  TransceiverM.UARTControl -> UARTPacket;
  TransceiverM.UARTSend -> UARTPacket;
  TransceiverM.UARTReceive -> UARTPacket;

  TransceiverM.PhotoADC -> Photo.PhotoADC;
  TransceiverM.PhotoControl -> Photo.StdControl;

  TransceiverM.TempADC -> Temp.TempADC;
  TransceiverM.TempControl -> Temp.StdControl;

#ifndef TOSH_HARDWARE_MICA2
  TransceiverM.Pot -> Pot;
#else
  TransceiverM.PowerControl -> CC1000ControlM;
#endif

  TransceiverM.Leds -> Leds;

  TransceiverM.Clock -> Clock;
}
