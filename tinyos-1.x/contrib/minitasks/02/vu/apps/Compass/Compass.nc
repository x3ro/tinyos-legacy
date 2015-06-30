/**
 * Compass - Copyright (c) 2003 ISIS
 *
 * Author: Peter Volgyesi
 **/

includes CompassMsg;

configuration Compass {
}
implementation {
  components Main, CompassM, ClockC, LedsC, SmartMagC, GenericComm as Comm;
  
  Main.StdControl -> CompassM;
  
  CompassM.Clock -> ClockC;
  CompassM.Leds -> LedsC;
  CompassM.SmartMagControl -> SmartMagC;
  CompassM.SmartMag -> SmartMagC;
  
  CompassM.CommControl -> Comm;
  CompassM.CalibrateMsg -> Comm.ReceiveMsg[AM_CALIBRATEMSG];
  CompassM.DataMsg -> Comm.SendMsg[AM_COMPASSMSG];
}

