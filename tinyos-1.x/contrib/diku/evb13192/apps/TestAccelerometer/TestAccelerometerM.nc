/*
    TestAccelerometer program - test the SARD board.
    Copyright (C) 2005 Marcus Chang <marcus@diku.dk>

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
 * This module tests the SARD board.
 * 
 * <p>A timer is fired, then the accelerometers are read. Upon
 * reading, the values are outputted on the UART.</p>
 *
 * @author Marcus Chang <marcus@diku.dk>.
 */
module TestAccelerometerM { 
    provides {
    interface StdControl;
  } uses {
    interface Leds;
    interface Timer;
    interface ConsoleOutput as Console;
    interface ADC as Xaxis;
    interface ADC as Yaxis;
    interface ADC as Zaxis;
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
    call Leds.init();

    call Console.print("\n\rTestAccelerometer online\n\r");


    return SUCCESS;
  }

  /**
   * Start the app - start the timer.
   * 
   * @return SUCCES if the timer.start call was a succes, FAIL otherwise.
   */
  command result_t StdControl.start() {
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

    if (SUCCESS != call Xaxis.getData()){ /* Will trigger an event, when read */
      call Console.print("Xaxis.getData FAIL!\n\r");
      call Leds.greenToggle();
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
  async event result_t Xaxis.dataReady(uint16_t data) {
    atomic {
      call Console.print("X: 0x");
      call Console.printHexword(data);
      // call Console.print("\n\r");
    }
    

    if (SUCCESS != call Yaxis.getData()){ 
      call Console.print("Yaxis.getData FAIL!\n\r");
      call Leds.yellowToggle();
    }

    
    return SUCCESS;
  }

  async event result_t Yaxis.dataReady(uint16_t data) {
    atomic {
      call Console.print(" - Y: 0x");
      call Console.printHexword(data);
      // call Console.print("\n\r");
    }

    if (SUCCESS != call Zaxis.getData()){ 
      call Console.print("Zaxis.getData FAIL!\n\r");
      call Leds.blueToggle();
    }

    return SUCCESS;
  }

  async event result_t Zaxis.dataReady(uint16_t data) {
    atomic {
      call Console.print(" - Z: 0x");
      call Console.printHexword(data);
      call Console.print("\n\r");
    }
    return SUCCESS;
  }


}
