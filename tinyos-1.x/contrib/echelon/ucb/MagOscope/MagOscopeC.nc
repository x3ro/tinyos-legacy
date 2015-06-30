
includes OscopeMsg;

/**
 * This configuration describes the MagOscope application,
 * a simple TinyOS app that periodically takes sensor readings
 * and sends a group of readings over the UART. The default
 * sensor used is the Photo component. This application uses 
 * the AM_OSCOPEMSG AM handler.
 */
configuration MagOscopeC
{
}
implementation
{
  components Main
           , MagOscopeM
	   , TimerC
	   , GenericComm as Comm
	   , MagSensorC
	   , LedsC
	   ;

  Main.StdControl -> MagOscopeM;
  Main.StdControl -> TimerC;
  Main.StdControl -> Comm;

  MagOscopeM.SensorControl -> MagSensorC;
  MagOscopeM.MagSensor -> MagSensorC;
  MagOscopeM.MagAxesSpecific -> MagSensorC;
  MagOscopeM.MagBiasActuator -> MagSensorC;
  //MagOscopeM.pulseSetReset -> HDMagC;

  MagOscopeM.Leds -> LedsC;
  MagOscopeM.Timer -> TimerC.Timer[unique("Timer")];

  MagOscopeM.ResetCounterMsg -> Comm.ReceiveMsg[AM_OSCOPERESETMSG];
  MagOscopeM.DataMsg -> Comm.SendMsg[AM_OSCOPEMSG];
}

