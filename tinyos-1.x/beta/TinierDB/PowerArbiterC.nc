includes PowerArbiter;

configuration PowerArbiterC {
  provides {
    interface PowerArbiter[uint8_t id];
  }
}
implementation {
  components Main, PowerArbiterM;

#if defined(PLATFORM_MICA2) || defined(PLATFORM_MICA2DOT)
  components CC1000RadioIntM as Radio, MicC as SensorBoard;

  PowerArbiterM.StdControl[PWR_RADIO] -> Radio.StdControl;
  PowerArbiterM.StdControl[PWR_SENSORB] -> SensorBoard.StdControl;

#elif defined(PLATFORM_PC)
  components MicaHighSpeedRadioM as Radio;

  PowerArbiterM.StdControl[PWR_RADIO] -> Radio.Control;

#endif

  Main.StdControl -> PowerArbiterM.StdControlInt;
  
  PowerArbiter = PowerArbiterM.PowerArbiter;
}
