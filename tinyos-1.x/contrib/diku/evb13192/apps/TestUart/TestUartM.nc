/* $Id: TestUartM.nc,v 1.2 2005/04/14 13:16:53 janflora Exp $ */
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
 * <p>The application will transmit a character on the UART once every
 * 250 ms, and at the same time toggle a led. Note that the Timer used
 * is a SingleTimer component, instead of the more advanced Timer
 * component.</p>
 *
 * <p>Also note, that this is not the way to get lots of output out on
 * the UART. If you want to write fast, put the next character to be
 * output in the Uart.putDone event! If you want an example of that, 
 * use the define below.</p>
 *
 * @author Mads Bondo Dydensborg, <madsdyd@diku.dk>
 */

/* Define this for continous output */
// #define CONT_OUT

module TestUartM {
  provides {
    interface StdControl;
  }
  uses {
    interface Timer;
    interface Leds;
    interface HPLUART as Uart;
  }
}
implementation {
  /* Component variables, shared between calls/events */

  /** The amazing string we are outputting. */
  uint8_t mystring[9] = "abcdefgh";
  /** When we are outputting, the index into our string. */
  uint8_t index;

  /* **********************************************************************
   * Setup/Init/StdControl code
   * *********************************************************************/

  /** Init.
   * 
   * <p>Inits the components that does not support StdControl, and
   * blink a toggle a couple of leds.</p>
   *
   * @return SUCCESS always.
   */
  command result_t StdControl.init() {
    call Leds.init();
    call Leds.redOn();
    call Uart.init();
    call Leds.greenToggle();
    atomic index = 0;
    return SUCCESS;
  }
  
  /** Start 
   * 
   * <p>Start the timer.</p>
   *
   * @return SUCCESS if the timer was started, FAIL otherwise.
   */
  command result_t StdControl.start() {
    call Leds.redOn();
    return call Timer.start(TIMER_REPEAT, 250);
  }

  /** Stop - never called.
   * 
   * <p>Stop the timer.</p>
   *
   * @return SUCCESS if the timer was stopped, FAIL otherwise.
  */
  command result_t StdControl.stop() {
    call Leds.redOff();
    return call Timer.stop();
  }

  /* **********************************************************************
   * Timer related code
   * *********************************************************************/
  
  /** Timer fired.
   *
   * <p>We transmit a char each timer the timer fires, and toggle the
   * yellow led.</p>
   *
   * <p>Note that the call to Uart.put2 is _not_ checked. If it fails,
   * it is because we are already in the process of transmitting a
   * character. In _both_ cases, updating the index is handled in
   * putDone.</p>
   *
   * @return SUCCESS always.
   */
  event result_t Timer.fired() {
    atomic call Uart.put2(&mystring[index], &mystring[index+1]);
    call Leds.yellowToggle();
    return SUCCESS;
  }

  /* **********************************************************************
   * Handle stuff from the Uart
   * *********************************************************************/

  /** "Proud little uart, done you are." 
   * 
   * <p>Update the index, toggle yellow.</p>
   *
   * @return SUCCESS always.
   */
  async event result_t Uart.putDone() {
    atomic {
      index++;
      if (index >= (sizeof(mystring)-1)) {
	index = 0;
      } 
      /* New line: Put more data out there.
         NOTE: If this line is present, the call in the timer fired
	 event will almost always (if not always) fail - it is
	 unneeded in other words.*/
#ifdef CONT_OUT
      call Uart.put2(&mystring[index], &mystring[index+1]);
#endif
    }
    call Leds.yellowToggle();
    return SUCCESS;
  }

  /** Receiving data on the Uart.
   *
   * <p>Happily ignore the data, but toggle green.</p>
   *
   * @return SUCCESS always.
   */
  async event result_t Uart.get(uint8_t uartData) {
    call Leds.greenToggle();
    return SUCCESS;
  }
  
}
