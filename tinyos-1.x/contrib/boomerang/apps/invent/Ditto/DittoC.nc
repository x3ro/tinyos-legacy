#include "Ditto.h"

configuration DittoC {
}
implementation {

  components Main;
  components new MainControlC() as MainMicC;
  components new MainControlC() as MainSpramC;
  components DittoP;
  components DelugeC;
  components new SpramC( NUM_SAMPLES );

#ifndef PLAYRECORD_NO_SPEAKER
  components SpeakerDriverC;
#endif
  components MicDriverC;

  components UserButtonAdvancedC;
  components LedsC;
  components new TimerMilliC() as LedsTimerC;

  components RandomC;
  components Counter32khzC;

  Main.StdControl -> DittoP;
  MainMicC.SplitControl -> MicDriverC;
  MainSpramC.Init -> SpramC;

  DittoP.Spram -> SpramC;

#ifndef PLAYRECORD_NO_SPEAKER
  DittoP.Speaker -> SpeakerDriverC;
  DittoP.SpeakerPowerKeepAlive -> SpeakerDriverC;
  DittoP.SpeakerPowerControl -> SpeakerDriverC;
#endif
  DittoP.Microphone -> MicDriverC;

  DittoP.Button -> UserButtonAdvancedC;
  DittoP.Leds -> LedsC;
  DittoP.LedsTimer -> LedsTimerC;

  DittoP.Random -> RandomC;
  DittoP.LocalTime32khz -> Counter32khzC;
}

