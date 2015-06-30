#include "antitheft.h"
#include "StorageVolumes.h"

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
  components ActiveMessageC, DisseminationC, CollectionC;
  MovingC.CommControl -> ActiveMessageC;
  MovingC.CollectionControl -> CollectionC;
  MovingC.DisseminationControl -> DisseminationC;

  /* Instantiate and wire our collection service for theft alerts */
  components new CollectionSenderC(COL_THEFT) as TheftSender;
  MovingC.Theft -> TheftSender;

  /* Instantiate and wire our dissemination service for theft settings */
  components new DisseminatorC(settings_t, DIS_THEFT);
  MovingC.Settings -> DisseminatorC;

  components new ConfigStorageC(VOLUME_AT_SETTINGS) as AtSettings;
  MovingC.Mount -> AtSettings;
  MovingC.ConfigStorage -> AtSettings;
}
