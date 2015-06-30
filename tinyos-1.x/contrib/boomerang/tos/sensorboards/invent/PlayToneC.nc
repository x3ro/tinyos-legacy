
configuration PlayToneC {
  provides interface PlayTone;
  provides interface PowerControl;
  provides interface PowerKeepAlive;
}
implementation {
  components MainPlayToneC;
  components PlayToneP;
  components SpeakerDriverC;
  components new TimerMilliC();

  PlayTone = PlayToneP;
  PowerControl = SpeakerDriverC;
  PowerKeepAlive = SpeakerDriverC;
  PlayToneP.Speaker -> SpeakerDriverC;
  PlayToneP.Timer -> TimerMilliC;
}

