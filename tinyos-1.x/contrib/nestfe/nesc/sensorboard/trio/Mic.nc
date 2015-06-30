//$Id: Mic.nc,v 1.2 2005/07/06 17:25:04 cssharp Exp $
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
 * Interface for Trio microphone <p>
 *
 * @modified 5/22/05
 *
 * @author Jaein Jeong
 */

interface Mic
{
  /**
   * Turns on the microphone.
   *
   * @return SUCCESS if the microphone is successfully turned on.
   */
  command result_t MicOn();
  /**
   * Turns off the microphone.
   *
   * @return SUCCESS if the microphone is successfully turned off.
   */
  command result_t MicOff();
  /**
   * Initiates an update of detect potentiometer with the given value.
   * @param val a value between 0 through 255 that will be written to
   * the potentiometer.
   * @return SUCCESS if the update is successfully requested.
   */
  command result_t adjustDetect(uint8_t val);
  /**
   * Initiates an update of gain potentiometer with the given value.
   * @param val a value between 0 through 255 that will be written to
   * the potentiometer.
   * @return SUCCESS if the update is successfully requested.
   */
  command result_t adjustGain(uint8_t val);
  /**
   * Initiates an update of first LPF potentiometer with the given value.
   * @param val a value between 0 through 255 that will be written to
   * the potentiometer.
   * @return SUCCESS if the update is successfully requested.
   */
  command result_t adjustLpfFreq0(uint8_t val);
  /**
   * Initiates an update of second LPF potentiometer with the given value.
   * @param val a value between 0 through 255 that will be written to
   * the potentiometer.
   * @return SUCCESS if the update is successfully requested.
   */
  command result_t adjustLpfFreq1(uint8_t val);
  /**
   * Initiates an update of first HPF potentiometer with the given value.
   * @param val a value between 0 through 255 that will be written to
   * the potentiometer.
   * @return SUCCESS if the update is successfully requested.
   */
  command result_t adjustHpfFreq0(uint8_t val);
  /**
   * Initiates an update of second HPF potentiometer with the given value.
   * @param val a value between 0 through 255 that will be written to
   * the potentiometer.
   * @return SUCCESS if the update is successfully requested.
   */
  command result_t adjustHpfFreq1(uint8_t val);
  /**
   * Initiates a read of detect potentiometer value.
   * @return SUCCESS if the read is successfully requested.
   */
  command result_t readDetect();
  /**
   * Initiates a read of gain potentiometer value.
   * @return SUCCESS if the read is successfully requested.
   */
  command result_t readGain();
  /**
   * Initiates a read of first LPF potentiometer value.
   * @return SUCCESS if the read is successfully requested.
   */
  command result_t readLpfFreq0();
  /**
   * Initiates a read of second LPF potentiometer value.
   * @return SUCCESS if the read is successfully requested.
   */
  command result_t readLpfFreq1();
  /**
   * Initiates a read of first HPF potentiometer value.
   * @return SUCCESS if the read is successfully requested.
   */
  command result_t readHpfFreq0();
  /**
   * Initiates a read of second HPF potentiometer value.
   * @return SUCCESS if the read is successfully requested.
   */
  command result_t readHpfFreq1();

  /**
   * Indicates that the update of detect potentiometer is done.
   * @param result SUCCESS if the update is successfully done.
   */
  event void adjustDetectDone(bool result);
  /**
   * Indicates that the update of gain potentiometer is done.
   * @param result SUCCESS if the update is successfully done.
   */
  event void adjustGainDone(bool result);
  /**
   * Indicates that the update of first LPF potentiometer is done.
   * @param result SUCCESS if the update is successfully done.
   */
  event void adjustLpfFreq0Done(bool result);
  /**
   * Indicates that the update of second LPF potentiometer is done.
   * @param result SUCCESS if the update is successfully done.
   */
  event void adjustLpfFreq1Done(bool result);
  /**
   * Indicates that the update of first HPF potentiometer is done.
   * @param result SUCCESS if the update is successfully done.
   */
  event void adjustHpfFreq0Done(bool result);
  /**
   * Indicates that the update of second HPF potentiometer is done.
   * @param result SUCCESS if the update is successfully done.
   */
  event void adjustHpfFreq1Done(bool result);
  /**
   * Indicates that the read of detect potentiometer is done.
   * @param val potentiometer value.
   */
  event void readDetectDone(uint8_t val);
  /**
   * Indicates that the read of gain potentiometer is done.
   * @param val potentiometer value.
   */
  event void readGainDone(uint8_t val);
  /**
   * Indicates that the read of first LPF potentiometer is done.
   * @param val potentiometer value.
   */
  event void readLpfFreq0Done(uint8_t val);
  /**
   * Indicates that the read of second LPF potentiometer is done.
   * @param val potentiometer value.
   */
  event void readLpfFreq1Done(uint8_t val);
  /**
   * Indicates that the read of first HPF potentiometer is done.
   * @param val potentiometer value.
   */
  event void readHpfFreq0Done(uint8_t val);
  /**
   * Indicates that the read of second HPF potentiometer is done.
   * @param val potentiometer value.
   */
  event void readHpfFreq1Done(uint8_t val);

  /**
   * Indicates that the microphone has detected the change 
   * in acoustic signal.
   */
  event void firedAcoustic();
}

