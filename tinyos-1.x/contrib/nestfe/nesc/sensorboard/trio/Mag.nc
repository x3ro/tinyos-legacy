//$Id: Mag.nc,v 1.2 2005/07/06 17:25:04 cssharp Exp $
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
 * Interface for Trio 2-axis magnetometers. <p>
 *
 * @modified 5/22/05
 *
 * @author Jaein Jeong
 */

interface Mag {
  /**
   * Turns on the magnetometer.
   *
   * @return SUCCESS if the magnetometer is successfully turned on.
   */
  command result_t MagOn();
  /**
   * Turns off the magnetometer.
   *
   * @return SUCCESS if the magnetometer is successfully turned off.
   */
  command result_t MagOff();
  /**
   * Initiates an update of X-axis magnetometer gain potentiometer
   * with the given value.
   * @param val a value between 0 through 255 that will be written to
   * the potentiometer.
   * @return SUCCESS if the update is successfully requested.
   */
  command result_t adjustGainX(uint8_t val);
  /**
   * Initiates an update of Y-axis magnetometer gain potentiometer
   * with the given value.
   * @param val a value between 0 through 255 that will be written to
   * the potentiometer.
   * @return SUCCESS if the update is successfully requested.
   */
  command result_t adjustGainY(uint8_t val);
  /**
   * Initiates a read of X-axis magnetometer gain potentiometer value.
   * @return SUCCESS if the read is successfully requested.
   */
  command result_t readGainX();
  /**
   * Initiates a read of Y-axis magnetometer gain potentiometer value.
   * @return SUCCESS if the read is successfully requested.
   */
  command result_t readGainY();
  /**
   * Turns on/off the set-reset pin of the magnetometer.
   * @return SUCCESS if the operation is successfully done.
   */
  command result_t SetReset();
  /**
   * Indicates that the update of X-axis magnetometer gain potentiometer
   * is done.
   *
   * @param result SUCCESS if the update is successfully done.
   */
  event void adjustGainXDone(bool result);
  /**
   * Indicates that the update of Y-axis magnetometer gain potentiometer
   * is done.
   *
   * @param result SUCCESS if the update is successfully done.
   */
  event void adjustGainYDone(bool result);
  /**
   * Indicates that the read of X-axis magnetometer gain potentiometer
   * is done.
   *
   * @param val potentiometer value.
   */
  event void readGainXDone(uint8_t val);
  /**
   * Indicates that the read of Y-axis magnetometer gain potentiometer
   * is done.
   *
   * @param val potentiometer value.
   */
  event void readGainYDone(uint8_t val);
}
