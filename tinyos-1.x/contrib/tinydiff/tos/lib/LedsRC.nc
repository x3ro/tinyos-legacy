configuration LedsRC {
  provides interface Leds;
  uses {
    interface ReceiveMsg;
    interface Enqueue;
  }
}
implementation {
  components LedsC, LedsRCM;

  LedsRCM.RealLeds -> LedsC;

  Leds = LedsRCM.Leds;
  ReceiveMsg = LedsRCM.ReceiveMsg;

  Enqueue = LedsRCM.Enqueue;
}
