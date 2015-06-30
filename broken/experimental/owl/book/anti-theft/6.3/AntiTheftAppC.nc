#include "antitheft.h"

configuration AntiTheftAppC { }
implementation {
  /* Blinking LED wiring */
  components AntiTheftC, MainC, LedsC;
  components new TimerMilliC() as WTimer;

  AntiTheftC.Boot -> MainC;
  AntiTheftC.Leds -> LedsC;
  AntiTheftC.WarningTimer -> WTimer;

  /* Movement detection wiring */
  components MovingC;
  components new TimerMilliC() as TTimer;
  components new AccelXStreamC();

  MovingC.Boot -> MainC;
  MovingC.Leds -> LedsC;
  MovingC.TheftTimer -> TTimer;
  MovingC.Accel -> AccelXStreamC;

  /* Communication wiring */
  components ActiveMessageC;
  components new AMSenderC(AM_THEFT) as SendTheft;
  components new AMReceiverC(AM_SETTINGS) as ReceiveSettings;

  MovingC.CommControl -> ActiveMessageC;
  MovingC.Theft -> SendTheft;
  MovingC.Settings -> ReceiveSettings;
}
