// $Id: OscilloscopeTmoteInventM.nc,v 1.1.1.1 2007/11/05 19:08:58 jpolastre Exp $

/*									tab:4
 * "Copyright (c) 2000-2003 The Regents of the University  of California.  
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
 *
 * Copyright (c) 2005 Moteiv Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached MOTEIV-LICENSE     
 * file. If you do not find these files, copies can be found at
 * http://www.moteiv.com/MOTEIV-LICENSE.txt and by emailing info@moteiv.com.
 *
 */

/**
 * Implementation of Oscilloscope for Tmote Invent.
 *
 * @author Joe Polastre, Moteiv Corporation <info@moteiv.com>
 */
module OscilloscopeTmoteInventM
{
  provides interface StdControl;
  uses {
    interface Timer;
    interface Leds;
    
    interface ADC as Photo;
    interface ADC as AccelX;
    interface ADC as AccelY;
    interface ADC as InternalTemperature;
    interface ADC as InternalVoltage;

    interface Oscope as OPhoto;
    interface Oscope as OAccelX;
    interface Oscope as OAccelY;
    interface Oscope as OInternalTemperature;
    interface Oscope as OInternalVoltage;
  }
}
implementation
{

  enum {
    OSCOPE_DELAY = 10,
  };

  enum {
    PHOTO,
    ACCELX,
    ACCELY,
    ITEMP,
    IVOLT
  };

  norace uint16_t photo, accelx, accely, itemp, ivolt;
  norace int state;

  /**
   * Used to initialize this component.
   */
  command result_t StdControl.init() {
    call Leds.init();
    call Leds.set(0);
    state = PHOTO;

    return SUCCESS;
  }

  /**
   * Starts the SensorControl component.
   * @return Always returns SUCCESS.
   */
  command result_t StdControl.start() {
    call Timer.start( TIMER_ONE_SHOT, 250 );
    return SUCCESS;
  }

  /**
   * Stops the SensorControl component.
   * @return Always returns SUCCESS.
   */
  command result_t StdControl.stop() {
    call Timer.stop();
    return SUCCESS;
  }

  event result_t Timer.fired() {
    // set a timeout in case a task post fails (rare)
    call Timer.start(TIMER_ONE_SHOT, 100);
    switch(state) {
    case PHOTO:
      call Photo.getData();
      break;
    case ACCELX:
      call AccelX.getData();
      break;
    case ACCELY:
      call AccelY.getData();
      break;
    case ITEMP:
      call InternalTemperature.getData();
      break;
    case IVOLT:
      call InternalVoltage.getData();
      break;
    default:
      call Timer.start(TIMER_ONE_SHOT, 10);
    }      
    return SUCCESS;
  }

  task void putPhoto() {
    call OPhoto.put(photo);
    call Leds.yellowOn();
    call Timer.start(TIMER_ONE_SHOT, OSCOPE_DELAY);
  }
  task void putAccelX() {
    call OAccelX.put(accelx);
    call Leds.greenOn();
    call Timer.start(TIMER_ONE_SHOT, OSCOPE_DELAY);
  }
  task void putAccelY() {
    call OAccelY.put(accely);
    call Timer.start(TIMER_ONE_SHOT, OSCOPE_DELAY);
  }
  task void putIntTemp() {
    call OInternalTemperature.put(itemp);
    call Leds.redOn();
    call Timer.start(TIMER_ONE_SHOT, OSCOPE_DELAY);
  }
  task void putIntVoltage() {
    call OInternalVoltage.put(ivolt);
    call Leds.set(0);
    call Timer.start(TIMER_ONE_SHOT, OSCOPE_DELAY);
  }

  async event result_t Photo.dataReady(uint16_t data) {
    photo = data;
    post putPhoto();
    state = ACCELX;
    return SUCCESS;
  }

  async event result_t AccelX.dataReady(uint16_t data) {
    accelx = data;
    post putAccelX();
    state = ACCELY;
    return SUCCESS;
  }


  async event result_t AccelY.dataReady(uint16_t data) {
    accely = data;
    post putAccelY();
    state = ITEMP;
    return SUCCESS;
  }

  async event result_t InternalTemperature.dataReady(uint16_t data) {
    itemp = data;
    post putIntTemp();
    state = IVOLT;
    return SUCCESS;
  }

  async event result_t InternalVoltage.dataReady(uint16_t data) {
    ivolt = data;
    post putIntVoltage();
    state = PHOTO;
    return SUCCESS;
  }
}
