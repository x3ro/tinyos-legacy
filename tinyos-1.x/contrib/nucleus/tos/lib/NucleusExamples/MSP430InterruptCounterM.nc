//$Id: MSP430InterruptCounterM.nc,v 1.2 2005/06/14 18:22:21 gtolle Exp $

module MSP430InterruptCounterM {
  uses {
    interface CounterEvent as NMI;

    interface CounterEvent as Port1;
    interface CounterEvent as Port2;

    interface CounterEvent as TimerA0;
    interface CounterEvent as TimerA1;
    interface CounterEvent as TimerB0;
    interface CounterEvent as TimerB1;
    
    interface CounterEvent as USART0RX;
    interface CounterEvent as USART0TX;
    interface CounterEvent as USART1RX;
    interface CounterEvent as USART1TX;

    interface CounterEvent as ADC;
  }
}
implementation {

  uint32_t timerA0Counter, timerA1Counter;
  uint32_t timerB0Counter, timerB1Counter;
  uint32_t usart0RXCounter, usart0TXCounter;
  uint32_t usart1RXCounter, usart1TXCounter;
  uint32_t port1Counter, port2Counter;
  uint32_t nmiCounter, adcCounter;

  async event void TimerA0.inc() {
    timerA0Counter++;
  }

  async event void TimerA1.inc() {
    timerA1Counter++;
  }

  async event void TimerB0.inc() {
    timerB0Counter++;
  }

  async event void TimerB1.inc() {
    timerB1Counter++;
  }

  async event void USART0RX.inc() {
    usart0RXCounter++;
  }

  async event void USART0TX.inc() {
    usart0TXCounter++;
  }

  async event void USART1RX.inc() {
    usart1RXCounter++;
  }

  async event void USART1TX.inc() {
    usart1TXCounter++;
  }

  async event void Port1.inc() {
    port1Counter++;
  }

  async event void Port2.inc() {
    port2Counter++;
  }

  async event void NMI.inc() {
    nmiCounter++;
  }

  async event void ADC.inc() {
    adcCounter++;
  }
}
