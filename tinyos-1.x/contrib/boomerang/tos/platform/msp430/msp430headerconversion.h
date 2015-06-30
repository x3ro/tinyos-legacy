// Converts new header definitions to old msp430-gcc header definitions
// for backwards compatability
// @author Joe Polastre, Moteiv Corporation <info@moteiv.com>
#ifndef MSP430HEADERCONVERSION_H
#define MSP430HEADERCONVERSION_H

#ifdef __MSP430_HAS_PORT1__
#define __msp430_have_port1
#endif

#ifdef __MSP430_HAS_PORT2__
#define __msp430_have_port2
#endif

#ifdef __MSP430_HAS_PORT3__
#define __msp430_have_port3
#endif

#ifdef __MSP430_HAS_PORT4__
#define __msp430_have_port4
#endif

#ifdef __MSP430_HAS_PORT5__
#define __msp430_have_port5
#endif

#ifdef __MSP430_HAS_PORT6__
#define __msp430_have_port6
#endif

#ifdef __MSP430_HAS_UART0__
#define __msp430_have_usart0
#endif

#ifdef __MSP430_HAS_UART1__
#define __msp430_have_usart1
#endif

#ifdef __MSP430_HAS_I2C__
#define __msp430_have_usart0_with_i2c
#endif

#ifdef __MSP430_HAS_TB7__
#define __msp430_have_timerb7
#endif

#ifdef __MSP430_HAS_SVS__
#define __msp430_have_svs_at_0x55
#endif

#endif
