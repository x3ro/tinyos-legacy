/*									tab:4
 *
 * "Copyright (c) 2001 and The Regents of the University 
 * of California.  All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice and the following
 * two paragraphs appear in all copies of this software.
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
 *
 * Authors:   David Culler
 * History:   created 6/28/2002
 *
 */
/**
 * Implementation for SenseLightToSounder application.
 * 
 * This application periodically checks the light reading and displays the
 * highest 3 bits of the raw ADC data to the LEDs.  If it is dark, the sounder 
 * buzzes for one clock tick.
 **/

module SenseLightToSounderM { 
  provides interface StdControl;
  uses {
    interface Clock;
    interface Leds;
    interface ADC;
    interface StdControl as ADCControl;
    interface StdControl as Sounder;
  }
}

implementation
{
  // declare module static variables here
  uint8_t soundOn;  // keep track of the state of the sounder

 /**
  * Initialize the component. Initialize ADCControl, Sounder, and Leds
  * 
  * @return returns <code>SUCCESS</code> or <code>FAILED</code>
  **/
  // implement StdControl interface 
  command result_t StdControl.init() {
    soundOn = 0;
    // initialize components
    return rcombine3(call ADCControl.init(),
		     call Sounder.init(),
		     call Leds.init());
  }

  /**
   * Start the component. Start the clock.
   * 
   * @return returns <code>SUCCESS</code> or <code>FAILED</code>
   **/
  command result_t StdControl.start() {
    // start the clock and set the firing rate
    return call Clock.setRate(TOS_I4PS, TOS_S4PS);
  }
  /**
   * Stop the component. Stop the clock.
   * 
   * @return returns <code>SUCCESS</code> or <code>FAILED</code>
   **/
  command result_t StdControl.stop() {
    // stop the clock
    return call Clock.setRate(0,0);
  }
  /**
   * Read sensor data in response to the <code>Clock.fire</code> event and
   * turn sounder off when time expires.
   *
   * @return returns <code>SUCCESS</code> or <code>FAILED</code>
   **/
  event result_t Clock.fire() {
    // get the adc data and modulate the sounder as necessary
    result_t ret = call ADC.getData();
    if (soundOn == 1) soundOn++;
    if (soundOn == 2) {
      call Sounder.stop();
      soundOn = 0;
    }
    return ret;
  }

  /**
    * Module scoped method.  Displays the lowest 3 bits to the LEDs,
    * with RED being the most signficant and YELLOW being the least significant.
    *
    * @return retruns <code>SUCCESS</code>
    **/
  result_t display(uint8_t val) {
    // display the 3 least significant bits of val on the leds
    if (val & 1) call Leds.yellowOn();
    else call Leds.yellowOff();
    if (val & 2) call Leds.greenOn();
    else call Leds.greenOff();
    if (val & 4) call Leds.redOn();
    else call Leds.redOff();
    return SUCCESS;
  }

  /**
   * Diaply the upper 3 bits of sensor reading to LEDs and turn sounder on if it is dark
   * in response to the <code>ADC.dataReady</code> event.  
   *
   * @return returns <code>SUCCESS</code>
   **/
  event result_t ADC.dataReady(uint16_t data) {
    // display the 3 most significant bits on the leds and beep if it is dark
    uint8_t displayBits = (data >> 7) & 0x7;
    display(7-displayBits);  // Invert display (will see leds when dark)
    if (displayBits < 4) {     // This number might change depending on sensor
      call Sounder.start();
      soundOn = 1;
    }
    return SUCCESS;
  }

}

