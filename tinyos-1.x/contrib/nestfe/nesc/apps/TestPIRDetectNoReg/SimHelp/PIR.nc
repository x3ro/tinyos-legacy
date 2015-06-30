/*
 * Copyright (c) 2000-2005 The Regents of the University  of California.  
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
 */

/**
 * Interface for Trio Passive Infra Red (PIR) sensor. <p>
 *
 * @modified 5/22/05
 *
 * @author Jaein Jeong
 */

interface PIR {
  /**
   * Turns on the PIR sensor.
   *
   * @return SUCCESS if the PIR sensor is successfully turned on.
   */
  command result_t PIROn();
  /**
   * Turns off the PIR sensor.
   *
   * @return SUCCESS if the PIR sensor is successfully turned off.
   */
  command result_t PIROff();
  /**
   * Initiates an update of detect potentiometer with the given value.
   * @param val a value between 0 through 255 that will be written to
   * the potentiometer.
   * @return SUCCESS if the update is successfully requested.
   */
  command result_t adjustDetect(uint8_t val);
  /**
   * Initiates an update of quad potentiometer with the given value.
   * @param val a value between 0 through 255 that will be written to
   * the potentiometer.
   * @return SUCCESS if the update is successfully requested.
   */
  command result_t adjustQuad(uint8_t val);
  /**
   * Initiates a read of detect potentiometer value.
   * @return SUCCESS if the read is successfully requested.
   */
  command result_t readDetect();
  /**
   * Initiates a read of quad potentiometer value.
   * @return SUCCESS if the read is successfully requested.
   */
  command result_t readQuad();
  /**
   * Indicates that the update of detect potentiometer is done.
   * @param result SUCCESS if the update is successfully done.
   */
  event void adjustDetectDone(bool result);
  /**
   * Indicates that the update of quad potentiometer is done.
   * @param result SUCCESS if the update is successfully done.
   */
  event void adjustQuadDone(bool result);
  /**
   * Indicates that the read of detect potentiometer is done.
   * @param val potentiometer value.
   */
  event void readDetectDone(uint8_t val);
  /**
   * Indicates that the read of quad potentiometer is done.
   * @param val potentiometer value.
   */
  event void readQuadDone(uint8_t val);

  /**
   * Indicates that the microphone has detected the change
   * in PIR sensor signal.
   */  
  event void firedPIR();
}

