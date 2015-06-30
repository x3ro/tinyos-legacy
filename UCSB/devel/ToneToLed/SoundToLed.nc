/**
 * Configuration for SoundToLed application.
 * Tests the Microphone.  Turns on the LEDs if the 
 * Mic detects any sound.
 *
 * We will build from there 
 **/

configuration SoundToLed {
// this module does not provide any interface
}
implementation {
  components Main, SoundToLedM, TimerC, LedsC, MicC;

  Main.StdControl -> SoundToLedM.StdControl;
  Main.StdControl -> TimerC;
  SoundToLedM.Timer -> TimerC.Timer[unique("Timer")];
  SoundToLedM.Leds -> LedsC;
  SoundToLedM.MicControl -> MicC;
  SoundToLedM.Mic -> MicC;
  SoundToLedM.MicADC -> MicC;
  
}
