configuration AntiTheftAppC { }
implementation {
  components AntiTheftC, MainC, LedsC;
  components new TimerMilliC() as WTimer;

  AntiTheftC.Boot -> MainC;
  AntiTheftC.Leds -> LedsC;
  AntiTheftC.WarningTimer -> WTimer;

  components MovingC;
  components new TimerMilliC() as TTimer;
  components new AccelXStreamC();

  MovingC.Boot -> MainC;
  MovingC.Leds -> LedsC;
  MovingC.TheftTimer -> TTimer;
  MovingC.Accel -> AccelXStreamC;
}
