// $Id: Microphone.nc,v 1.1.1.1 2007/11/05 19:11:36 jpolastre Exp $
/*
 * Copyright (c) 2005 Moteiv Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached MOTEIV-LICENSE     
 * file. If you do not find these files, copies can be found at
 * http://www.moteiv.com/MOTEIV-LICENSE.txt and by emailing info@moteiv.com.
 */

/**
 * Interface for sampling data from a microphone.
 *
 * @author Joe Polastre, Moteiv Corporation <info@moteiv.com>
 */
interface Microphone {
  /**
   * Start receiving data from a microphone and store the data at
   * a specified address in memory.
   *
   * @param addr Memory address of first sample
   * @param length The length of the audio sample
   * @param freq Time between samples in microseconds
   * @param repeat TRUE to repeat the transfer and ask for the next buffer,
   *               FALSE to only take 'length' samples and then stop
   * @return SUCCESS if the playback can begin immediately
   */
  command result_t start(void* addr, uint16_t length, uint16_t freq, bool repeat);

  /**
   * Stop the current recording.  If no sampling is underway or if the samples
   * cannot be stopped, FAIL will be returned by stop().  If
   * a sample is being recorded, after it is stopped with the stop() command,
   * a done() event will be signalled to notify the caller that the buffer
   * is now free and recording has halted.
   *
   * @return SUCCESS if playback is halted (a done() event will be signalled),
   *         FAIL if no sample is playing or if it cannot be halted.
   */
  async command result_t stop();

  /**
   * Notification that the buffer is no longer in use.  done() is fired
   * after a single sample recording (start() with repeat = FALSE) or
   * after stop() is called.
   *
   * @param addr Address of the audio sample
   * @param length Length of the audio sample
   * @param freq Frequency of the recorded audio sample (in us)
   */
  async event void done(void* addr, uint16_t length);

  /**
   * repeatStart() may only be called inside a "repeat()" event
   *
   * The purpose of this function is to keep the same settings but
   * change the buffer used for sampling the microphone
   *
   * @param addr New address for the next set of samples
   * @param length number of samples to acquire
   *
   * @return SUCCESS if the new settings are accepted
   */
  async command result_t repeatStart(void* addr, uint16_t length);

  /**
   * Notification that the sampling process is repeating.  A new buffer
   * and length MUST BE IMMEDIATELY returned to the caller through the 
   * repeatStart() command.  If FAIL is returned,
   * recording halts and a done() event is signalled.
   */
  async event result_t repeat(void* addr, uint16_t length);
}
