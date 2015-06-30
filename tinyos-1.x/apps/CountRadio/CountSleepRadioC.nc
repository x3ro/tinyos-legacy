// $Id: CountSleepRadioC.nc,v 1.4 2005/09/15 00:37:10 jpolastre Exp $
// @author Joe Polastre

includes CountMsg;

/** CountSleepRadio wakes up every 2 seconds, starts the radio,
 * sends a packet with the current count, and then immediately shuts off
 * the radio and UART via the GenericComm StdControl interface.
 * CountSleepRadio is *only* a transmitter, there is no reception ability
 * in this example application.
 */
configuration CountSleepRadioC
{
}
implementation
{
  components Main
           , CountSleepRadioM
	   , TimerC
           , GenericComm as Comm
	   , LedsC
// HPLPowerManagement is only needed for AVR based platforms
#ifdef __AVR__
           , HPLPowerManagementM as PM
#endif
	   ;

#ifdef __AVR__
  CountSleepRadioM.PowerManagement -> PM;
  CountSleepRadioM.Enable -> PM.Enable;
#endif

  Main.StdControl -> TimerC;
  Main.StdControl -> CountSleepRadioM;

  CountSleepRadioM.CommControl -> Comm;
  CountSleepRadioM.SendMsg -> Comm.SendMsg[AM_COUNTMSG];
  CountSleepRadioM.Timer -> TimerC.Timer[unique("Timer")];
  CountSleepRadioM.Leds -> LedsC.Leds;
}

