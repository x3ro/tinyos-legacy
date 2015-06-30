/*
    TestLightTemp program - test the ligthtemp sensorboard.
    Copyright (C) 2004 Mads Bondo Dydensborg <madsdyd@diku.dk>

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



/**
 * This module tests the lighttemp sensorboard.
 * 
 * <p>A timer is fired, then the light and temp sensors are read. Upon
 * reading, the values are outputted on the UART.</p>
 *
 * @author Mads Bondo Dydensborg, <madsdyd@diku.dk>.
 */
module TestLightTempM { 
  provides {
    interface StdControl;
  }
  uses {
    interface Leds;
    interface Timer;
    interface Console;
    interface ADC as Light;
    interface ADC as Temp;
  }
}
implementation {

  /* **********************************************************************
   * StdControl stuff
   * *********************************************************************/

  /** 
   * Init - init the Console.
   * 
   * @return SUCCESS always.
   */
  command result_t StdControl.init() {
    return call Leds.init() && call Console.init();
  }

  /**
   * Start the app - start the timer.
   * 
   * @return SUCCES if the timer.start call was a succes, FAIL otherwise.
   */
  command result_t StdControl.start() {
    call Console.print("\n\rTestLightTemp online\n\r");
    return call Timer.start(TIMER_REPEAT, 1000);
  }
  
  /**
   * Stop the app - stop the timer.
   * 
   * @return SUCCES if the timer.stop call was a succes, FAIL otherwise.
   */
  command result_t StdControl.stop() {
    return call Timer.stop();
  }

  /* **********************************************************************
   * Timer stuff
   * *********************************************************************/
  
  /**
   * Start an ADC sample.
   *
   * <p>When the timer triggers, start an ADC sample. When the ADC is
   * done, it will trigger the dataReady event.</p>
   *
   * @return SUCCESS if the getData call to the ADC was a succes, FAIL
   * otherwise.
   */
  event result_t Timer.fired() {
    call Leds.redToggle();
    if (SUCCESS != call Light.getData()){ /* Will trigger an event, when read */
      call Console.print("Light.getData FAIL!\n\r");
      call Leds.greenToggle();
    }
    if (SUCCESS != call Temp.getData()){ /* Will trigger an event, when read */
      call Console.print("Temp.getData FAIL!\n\r");
      call Leds.yellowToggle();
    }
    return SUCCESS;
  }

  /* **********************************************************************
   * ADC stuff
   * *********************************************************************/

  /** 
   * Data read from the ADC.
   *
   * <p>There are data available from the ADC.</p>
   *
   * @param data The data that have been sampled
   * @return SUCCESS
   */
  async event result_t Light.dataReady(uint16_t data) {
    atomic {
      call Console.print("Light: 0x");
      call Console.printHexword(data);
      // call Console.print("\n\r");
    }
    return SUCCESS;
  }

  async event result_t Temp.dataReady(uint16_t data) {
    atomic {
      call Console.print(" - Temp: 0x");
      call Console.printHexword(data);
      call Console.print("\n\r");
    }
    return SUCCESS;
  }


  /* **********************************************************************
   * Console stuff
   * *********************************************************************/
  /**
   * Console got input.
   * 
   * <p>For now, simply send it back.</p>
   *
   * @param data The data that was input'ed to the Console.
   */
  async event result_t Console.get(uint8_t data) {
    char foo[2];
    foo[0] = data;
    foo[1] = 0;
    return call Console.print(foo);
  }

}
