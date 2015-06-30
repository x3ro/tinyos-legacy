//Mohammad Rahimi
includes IB;

configuration CounterC {
  provides {
      //interface DioControl;
      interface StdControl as CounterControl;
      interface Dio as Counter;
  }
}
implementation {
    components LedsC,CounterM;
    CounterControl =  CounterM.CounterControl;
    Counter = CounterM.Counter;
    CounterM.Leds -> LedsC.Leds;
}
