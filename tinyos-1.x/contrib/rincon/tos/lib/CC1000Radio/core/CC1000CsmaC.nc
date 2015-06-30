
/**
 * CC1000 CSMA Configuration
 * Provides the low power listening functionality for the CC1000 radio
 * 
 * @author David Moss
 */

configuration CC1000CsmaC {
  provides {
    interface StdControl;
    interface LowPowerListening;
    interface CsmaBackoff;
    interface CsmaControl;
  }
}

implementation {
  components CC1000CsmaM, CC1000ControlC, RandomC, TimerC, BusyWaitM;
  components CC1000SquelchM, CC1000SendReceiveC, CC1000RssiC;

  StdControl = CC1000CsmaM;
  LowPowerListening = CC1000CsmaM;
  CsmaBackoff = CC1000CsmaM;
  CsmaControl = CC1000CsmaM;
  
  CC1000CsmaM.CC1000Control -> CC1000ControlC;
  CC1000CsmaM.Random -> RandomC;
  CC1000CsmaM.CC1000Squelch -> CC1000SquelchM;
  CC1000CsmaM.WakeupTimer -> TimerC.Timer[unique("Timer")];
  CC1000CsmaM.RssiNoiseFloor -> CC1000RssiC.Rssi[unique("Rssi")];
  CC1000CsmaM.RssiCheckChannel -> CC1000RssiC.Rssi[unique("Rssi")];
  CC1000CsmaM.RssiPulseCheck -> CC1000RssiC.Rssi[unique("Rssi")];
  CC1000CsmaM.BusyWait -> BusyWaitM;
  CC1000CsmaM.ByteRadio -> CC1000SendReceiveC;
  CC1000CsmaM.ByteRadioControl -> CC1000SendReceiveC.StdControl;

}


