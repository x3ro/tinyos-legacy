configuration AntiTheftAppC { }
implementation {
  components AntiTheftC, MainC, LedsC;
  components new TimerMilliC() as WTimer;

  AntiTheftC.Boot -> MainC;
  AntiTheftC.Leds -> LedsC;
  AntiTheftC.WarningTimer -> WTimer;
}
