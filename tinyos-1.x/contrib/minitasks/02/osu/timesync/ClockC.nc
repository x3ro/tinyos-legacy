// differs from tos/system/ClockC.nc as follows:
// (1) supports additional new interface, readClock
// (2) wires ClockM to support the new interface
// herman@cs.uiowa.edu Jan 2003
configuration ClockC {
  provides interface Clock;
  provides interface readClock;
}
implementation 
{
  components ClockM, HPLClock;
  ClockM.HPLClock -> HPLClock.Clock;
  Clock = ClockM;
  readClock = ClockM;
}
