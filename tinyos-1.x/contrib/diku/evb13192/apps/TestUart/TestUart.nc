/* $Id: TestUart.nc,v 1.1 2005/01/31 21:04:54 freefrag Exp $ */
/** Test application for SimpleMac

  Copyright (C) 2004 Mads Bondo Dydensborg, <madsdyd@diku.dk>

  This program is free software; you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation; either version 2 of the License, or
  (at your option) any later version.

  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with this program; if not, write to the Free Software
  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

*/

/** Test/Demo application, that uses the UART.
 *
 * <p>This is a very simplistic test/demo application.</p>
 *
 * <p>The application will transmit a character on the UART once a
 * second, and at the same time toggle a led. Note that the Timer used
 * is a SingleTimer component, instead of the more advanced Timer
 * component.</p>
 *
 * @author Mads Bondo Dydensborg, <madsdyd@diku.dk>
 */
configuration TestUart {
}
implementation {
  /* Include the needed components */
  components Main, TestUartM, SingleTimer, LedsC, HPLUART0C;

  /* Wire the interfaces that TestUartM needs onto the components */
  TestUartM.Timer -> SingleTimer.Timer;
  TestUartM.Leds  -> LedsC;
  TestUartM.Uart  -> HPLUART0C; 
  
  /* Wire up the StdControl interfaces to main */
  Main.StdControl -> SingleTimer.StdControl;
  Main.StdControl -> TestUartM.StdControl;
}






