
/**
 * CC1000Control Configuration
 * The CC1000Control will set the state of the CC1000 radio chip, 
 * turn it on and off, configure it, etc.
 *
 * @author David Moss
 */
configuration CC1000ControlC {
  provides {
    interface StdControl;
    interface CC1000Control;
  }
}

implementation {
  components CC1000ControlM, HPLCC1000M, BusyWaitM, TimerC, CC1000SendReceiveC;
  
  StdControl = CC1000ControlM;
  CC1000Control = CC1000ControlM;
  
  CC1000ControlM.RecalibrationTimer -> TimerC.Timer[unique("Timer")];
  CC1000ControlM.HPLCC1000 -> HPLCC1000M;
  CC1000ControlM.BusyWait -> BusyWaitM;
  CC1000ControlM.ByteRadio -> CC1000SendReceiveC;
}

