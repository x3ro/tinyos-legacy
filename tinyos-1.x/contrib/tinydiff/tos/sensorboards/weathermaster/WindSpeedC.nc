//Mohammad Rahimi
includes IB;

configuration WindSpeedC {
  provides {
      //interface DioControl;
      interface StdControl as WindSpeedControl;
      interface Dio as WindSpeed;
      interface Dio as WindGust;
  }
}
implementation {
    components LedsC,WindSpeedM;
    WindSpeedControl =  WindSpeedM.WindSpeedControl;
    WindSpeed = WindSpeedM.WindSpeed;
    WindGust = WindSpeedM.WindGust;
    WindSpeedM.Leds -> LedsC.Leds;
}
