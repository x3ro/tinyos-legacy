/* "Copyright (c) 2000-2002 The Regents of the University of California.  
 * All rights reserved.
 * 
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY OF
 * CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 */

// Authors: Cory Sharp
// $Id: UARTBaudRateM.nc,v 1.3 2003/08/19 06:59:06 cssharp Exp $

includes UARTBaudRate;

module UARTBaudRateM
{
  provides interface StdControl;
  provides interface UARTBaudRate;
}
implementation
{
  uint8_t m_baud;

#if defined(PLATFORM_MICA2)

  void setUBRR( uint8_t ubrr )
  {
    outp( 0, UBRR0H ); 
    outp( ubrr, UBRR0L );
  }

  command UARTBaudRate_t UARTBaudRate.set( UARTBaudRate_t baud )
  {
    uint8_t ubrr;

    switch( baud )
    {
      case UART_2400_BAUD: ubrr = 191; break;
      case UART_4800_BAUD: ubrr = 95; break;
      case UART_9600_BAUD: ubrr = 47; break;
      case UART_14400_BAUD: ubrr = 31; break;
      case UART_19200_BAUD: ubrr = 23; break;
      case UART_28800_BAUD: ubrr = 15; break;
      case UART_38400_BAUD: ubrr = 11; break;
      case UART_57600_BAUD: ubrr = 7; break;
      case UART_76800_BAUD: ubrr = 5; break;
      case UART_115200_BAUD: ubrr = 3; break;
      default: ubrr = 7; baud = UART_57600_BAUD;
    }

    setUBRR( ubrr );
    return baud;
  }

#elif defined(PLATFORM_MICA2DOT)

  void setUBRR( uint8_t ubrr )
  {
    outp( 0, UBRR0H ); 
    outp( ubrr, UBRR0L );
  }

  command UARTBaudRate_t UARTBaudRate.set( UARTBaudRate_t baud )
  {
    uint8_t ubrr;

    switch( baud )
    {
      case UART_1200_BAUD: ubrr = 207; break;
      case UART_2400_BAUD: ubrr = 103; break;
      case UART_4800_BAUD: ubrr = 51; break;
      case UART_9600_BAUD: ubrr = 25; break;
      case UART_19200_BAUD: ubrr = 12; break;
      case UART_28800_BAUD: ubrr = 8; break;
      case UART_38400_BAUD: ubrr = 6; break;
      case UART_57600_BAUD: ubrr = 3; break;
      case UART_76800_BAUD: ubrr = 2; break;
      case UART_115200_BAUD: ubrr = 1; break;
      default: ubrr = 12; baud = UART_19200_BAUD;
    }

    setUBRR( ubrr );
    return baud;
  }

#else

  void setUBRR( uint8_t ubrr )
  {
    outp( 0, UCR );
    outp( ubrr, UBRR );
    inp( UDR );
    outp( 0xd8, UCR );
  }

  command UARTBaudRate_t UARTBaudRate.set( UARTBaudRate_t baud )
  {
    uint8_t ubrr;

    switch( baud )
    {
      case UART_1200_BAUD: ubrr = 207; break;
      case UART_2400_BAUD: ubrr = 103; break;
      case UART_4800_BAUD: ubrr = 51; break;
      case UART_9600_BAUD: ubrr = 25; break;
      case UART_19200_BAUD: ubrr = 12; break;
      default: ubrr = 12; baud = UART_19200_BAUD;
    }

    setUBRR( ubrr );
    return baud;
  }

#endif

  default event UARTBaudRate_t UARTBaudRate.getInitial()
  {
    return UART_19200_BAUD;
  }

  task void setBaudRate()
  {
    m_baud = call UARTBaudRate.set( m_baud );
  }

  command result_t StdControl.init()
  {
    m_baud = signal UARTBaudRate.getInitial();
    return post setBaudRate();
  }

  command result_t StdControl.start()
  {
    return post setBaudRate();
  }

  command result_t StdControl.stop()
  {
    return SUCCESS;
  }
} 

