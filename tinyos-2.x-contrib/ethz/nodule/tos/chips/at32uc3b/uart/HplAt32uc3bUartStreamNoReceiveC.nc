/* $Id: HplAt32uc3bUartStreamNoReceiveC.nc,v 1.2 2008/03/09 16:36:17 yuecelm Exp $ */

/* @author Mustafa Yuecel <mustafa.yuecel@alumni.ethz.ch> */

#include "at32uc3b_uart.h"

configuration HplAt32uc3bUartStreamNoReceiveC
{
  provides {
    interface Init as Uart0Init;
    interface UartStream as Uart0;
    interface Init as Uart1Init;
    interface UartStream as Uart1;
    interface Init as Uart2Init;
    interface UartStream as Uart2;
  }
  uses {
    interface PeripheralDmaController as Uart0DmaTx;
    interface PeripheralDmaController as Uart1DmaTx;
    interface PeripheralDmaController as Uart2DmaTx;
  }
}
implementation
{
  components PeripheralDmaControllerC, InterruptControllerC, 
    new HplAt32uc3bUartStreamNoReceiveP(0) as UART0, 
    new HplAt32uc3bUartStreamNoReceiveP(1) as UART1, 
    new HplAt32uc3bUartStreamNoReceiveP(2) as UART2;

  // wiring directly with the PeripheralDmaController is a waste of PDCA channels (else 3 of 7 channels are allocated)

  Uart0 = UART0;
  Uart0DmaTx = UART0.DmaTx;
//  UART0.DmaTx -> PeripheralDmaControllerC.Usart0Tx[unique("Pdca")];
  UART0.InterruptController -> InterruptControllerC;
  Uart0Init = UART0;

  Uart1 = UART1;
  Uart1DmaTx = UART1.DmaTx;
//  UART1.DmaTx -> PeripheralDmaControllerC.Usart1Tx[unique("Pdca")];
  UART1.InterruptController -> InterruptControllerC;
  Uart1Init = UART1;

  Uart2 = UART2;
  Uart2DmaTx = UART2.DmaTx;
//  UART2.DmaTx -> PeripheralDmaControllerC.Usart2Tx[unique("Pdca")];
  UART2.InterruptController -> InterruptControllerC;
  Uart2Init = UART2;

  components HplAt32uc3bGeneralIOC as Gpio;

#ifndef AVR32_USART0_ALTERNATIVE_GPIO_MAPPING
  UART0.Tx -> Gpio.Gpio43;
//  UART0.Rx -> Gpio.Gpio42;
#else
  // GPIO 18/19 is also used as oscillator pinout (xin0, xout0)
  UART0.Tx -> Gpio.Gpio19;
//  UART0.Rx -> Gpio.Gpio18;
#endif

#ifndef AVR32_USART1_ALTERNATIVE_GPIO_MAPPING
  // wired to RS232 interface in EVK1101
  UART1.Tx -> Gpio.Gpio23;
//  UART1.Rx -> Gpio.Gpio24;
#else
  UART1.Tx -> Gpio.Gpio34;
//  UART1.Rx -> Gpio.Gpio35;
#endif

#ifndef AVR32_USART2_ALTERNATIVE_GPIO_MAPPING
  // GPIO 26 is wired as USB_ID in EVK1101
  UART2.Tx -> Gpio.Gpio26;
//  UART2.Rx -> Gpio.Gpio27;
#else
  // GPIO 21 is wired as LED2 in EVK1101
  UART2.Tx -> Gpio.Gpio21;
  // GPIO 20 is used for USB overcurrent detection in EVK1101
//  UART2.Rx -> Gpio.Gpio20;
#endif
}
