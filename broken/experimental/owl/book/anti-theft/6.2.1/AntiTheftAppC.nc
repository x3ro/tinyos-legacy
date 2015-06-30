configuration AntiTheftAppC { }
implementation {
  components AntiTheftC, MainC, LedsC;
  components new TimerMilliC() as WTimer;

  AntiTheftC.Boot -> MainC;
  AntiTheftC.Leds -> LedsC;
  AntiTheftC.WarningTimer -> WTimer;

  components DarkC;
  components new TimerMilliC() as TTimer;
  components new PhotoC();

  DarkC.Boot -> MainC;
  DarkC.Leds -> LedsC;
  DarkC.TheftTimer -> TTimer;
  DarkC.Light -> PhotoC;
}
