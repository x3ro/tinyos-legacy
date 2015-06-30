//Mohammad Rahimi
includes IB;
configuration SamplerC
{
  provides {      
      interface StdControl as SamplerControl;
      interface Sampler as BufferAnalog;
      interface Sampler as BufferRain;
      interface Sampler as BufferWind;
 }
}
implementation
{
    components Main,SamplerM,LedsC,TimerC,DioC,IBADC,BatteryC,WindSpeedC;

    SamplerM.SamplerControl = SamplerControl;
    SamplerM.Leds -> LedsC;

    //Timing management
    SamplerM.AnalogTimer -> TimerC.Timer[unique("Timer")];
    SamplerM.RainTimer -> TimerC.Timer[unique("Timer")];
    SamplerM.WindTimer -> TimerC.Timer[unique("Timer")];
    SamplerM.GustTimer -> TimerC.Timer[unique("Timer")];
    SamplerM.debouncer -> TimerC.Timer[unique("Timer")];
    //SamplerM.IBADCcontrol -> I2CADCC.IBADCcontrol;
    SamplerM.ADC0 -> IBADC.ADC[0];
    SamplerM.ADC1 -> IBADC.ADC[1];
    SamplerM.ADC2 -> IBADC.ADC[2];
    SamplerM.ADC3 -> IBADC.ADC[3];
    SamplerM.ADC4 -> IBADC.ADC[4];
    SamplerM.ADC5 -> IBADC.ADC[5];
    SamplerM.ADC6 -> IBADC.ADC[6];
    SamplerM.ADC7 -> IBADC.ADC[7];
    SamplerM.Excite -> IBADC.Excite;
    SamplerM.BatteryADC -> BatteryC.ExternalBatteryADC;
    SamplerM.BatteryControl -> BatteryC.StdControl;
    SamplerM.IBADCcontrol -> IBADC.StdControl;
 
    //Digital input channels
    SamplerM.Rain1 -> DioC.Dio[1];
    SamplerM.Rain2 -> DioC.Dio[2];
    SamplerM.EventSwitch1 -> DioC.Dio[3];
    //    SamplerM.Wind1 -> DioC.Dio[4];
    SamplerM.EventSwitch2 -> DioC.Dio[5];
    SamplerM.AttentionSwitch -> DioC.Dio[6];
    SamplerM.DioControl -> DioC.StdControl;
    
    SamplerM.WindSpeed -> WindSpeedC.WindSpeed;
    SamplerM.WindGust -> WindSpeedC.WindGust;
    SamplerM.WindSpeedControl -> WindSpeedC.WindSpeedControl;

    //Communication management
    SamplerM.BufferAnalog = BufferAnalog;
    SamplerM.BufferRain = BufferRain;
    SamplerM.BufferWind = BufferWind;

 }
