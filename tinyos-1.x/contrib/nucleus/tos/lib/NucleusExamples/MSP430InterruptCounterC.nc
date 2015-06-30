//$Id: MSP430InterruptCounterC.nc,v 1.2 2005/06/14 18:22:21 gtolle Exp $

configuration MSP430InterruptCounterC {
}
implementation {
  components MSP430InterruptCounterM;
  components MSP430InterruptM, MSP430TimerM, HPLUSART0M, HPLUSART1M, HPLADC12M;

  MSP430InterruptCounterM.NMI -> MSP430InterruptM.NMICounter;
  MSP430InterruptCounterM.Port1 -> MSP430InterruptM.Port1Counter;
  MSP430InterruptCounterM.Port2 -> MSP430InterruptM.Port2Counter;

  MSP430InterruptCounterM.TimerA0 -> MSP430TimerM.TimerA0Counter;
  MSP430InterruptCounterM.TimerA1 -> MSP430TimerM.TimerA1Counter;
  MSP430InterruptCounterM.TimerB0 -> MSP430TimerM.TimerB0Counter;
  MSP430InterruptCounterM.TimerB1 -> MSP430TimerM.TimerB1Counter;

  MSP430InterruptCounterM.USART0RX -> HPLUSART0M.USARTRXCounter;
  MSP430InterruptCounterM.USART0TX -> HPLUSART0M.USARTTXCounter;
  MSP430InterruptCounterM.USART1RX -> HPLUSART1M.USARTRXCounter;
  MSP430InterruptCounterM.USART1TX -> HPLUSART1M.USARTTXCounter;

  MSP430InterruptCounterM.ADC -> HPLADC12M.ADCCounter;
}





  
