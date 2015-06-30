//Mohammad Rahimi
includes IB;
configuration SamplerC
{
  provides {      
      interface StdControl as SamplerControl;
      interface Sample;
 }
}
implementation
{
    components Main,SamplerM,LedsC,TimerC,DioC,IBADC,CounterC,TempHumM,BatteryC;

    SamplerM.SamplerControl = SamplerControl;
    SamplerM.Sample = Sample;
    SamplerM.Leds -> LedsC;
    TempHumM.Leds -> LedsC;

    //Timing management
    SamplerM.SamplerTimer -> TimerC.Timer[unique("Timer")];

    //analog channels
    SamplerM.IBADCcontrol -> IBADC.StdControl;
    SamplerM.Excite -> IBADC.Excite;
    SamplerM.ADC0 -> IBADC.ADC[0];
    SamplerM.ADC1 -> IBADC.ADC[1];
    SamplerM.ADC2 -> IBADC.ADC[2];
    SamplerM.ADC3 -> IBADC.ADC[3];
    SamplerM.ADC4 -> IBADC.ADC[4];
    SamplerM.ADC5 -> IBADC.ADC[5];
    SamplerM.ADC6 -> IBADC.ADC[6];
    SamplerM.ADC7 -> IBADC.ADC[7];
    SamplerM.ADC8 -> IBADC.ADC[8];
    SamplerM.ADC9 -> IBADC.ADC[9];
    SamplerM.ADC10 -> IBADC.ADC[10];
    SamplerM.ADC11 -> IBADC.ADC[11];
    SamplerM.ADC12 -> IBADC.ADC[12];
    SamplerM.ADC13 -> IBADC.ADC[13];

    //health channels
    SamplerM.BatteryControl -> BatteryC.StdControl;
    SamplerM.Battery -> BatteryC.Battery;
    SamplerM.TempHumControl -> TempHumM.StdControl;
    SamplerM.Temp -> TempHumM.TempSensor;
    SamplerM.Hum -> TempHumM.HumSensor;
 
    //Digital input channels
    SamplerM.DioControl -> DioC.StdControl;
    SamplerM.Dio0 -> DioC.Dio[0];
    SamplerM.Dio1 -> DioC.Dio[1];
    SamplerM.Dio2 -> DioC.Dio[2];
    SamplerM.Dio3 -> DioC.Dio[3];
    SamplerM.Dio4 -> DioC.Dio[4];
    SamplerM.Dio5 -> DioC.Dio[5];
    SamplerM.Dio6 -> DioC.Dio[6];
    SamplerM.Dio7 -> DioC.Dio[7];

    //counter channels
    SamplerM.CounterControl -> CounterC.CounterControl;    
    SamplerM.Counter -> CounterC.Counter;
  }
