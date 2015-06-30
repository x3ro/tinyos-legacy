/* 
*/

configuration ADCTest {
}
implementation {
  components Main, ADCTestM, ADCC, TimerC;
  Main.StdControl -> ADCTestM;
  Main.StdControl -> TimerC;
  ADCTestM.Timer -> TimerC.Timer[unique("Timer")];
  ADCTestM.ADC -> ADCC.ADC[0];
  ADCTestM.ADCControl -> ADCC;
}
