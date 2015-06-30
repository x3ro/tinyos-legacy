// $Id: Speaker.nc,v 1.1.1.1 2007/11/05 19:11:36 jpolastre Exp $
/*
 * Copyright (c) 2005 Moteiv Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached MOTEIV-LICENSE     
 * file. If you do not find these files, copies can be found at
 * http://www.moteiv.com/MOTEIV-LICENSE.txt and by emailing info@moteiv.com.
 */

/**
 * Interface for sending sound through a speaker.
 *
 * @author Joe Polastre, Moteiv Corporation <info@moteiv.com>
 */
interface Speaker {
  /**
   * Start sending sound through a speaker based on data at
   * a specified address in memory.
   *
   * @param addr Memory address of first sample
   * @param length The length of the audio sample
   * @param word TRUE if 12-bit data, FALSE for 8-bit data
   * @param freq Frequency that the audio sample was recorded
   * @param repeat TRUE to repeat the sample infinitely, FALSE to play once
   * @return SUCCESS if the playback can begin immediately
   */
  command result_t start(void* addr, uint16_t length, bool word, uint16_t freq, bool repeat);

  /**
   * Stop the currently playing sample.  If no sample is playing or if the
   * playback cannot be stopped, FAIL will be returned by stop().  If
   * a sample is being played, after it is stopped with the stop() command,
   * a done() event will be signalled to notify the caller that the buffer
   * is now free and playback has halted.
   *
   * @return SUCCESS if playback is halted (a done() event will be signalled),
   *         FAIL if no sample is playing or if it cannot be halted.
   */
  async command result_t stop();

  /**
   * Notification that the audio sample has started playing
   *
   * @param addr Address of the audio sample
   * @param length Length of the audio sample
   */
  event void started(void* addr, uint16_t length, result_t result);

  /**
   * Notification that the sample is no longer in use.  done() is fired
   * after a single sample playback (start() with repeat = FALSE) or
   * after stop() is called.
   *
   * @param addr Address of the audio sample
   * @param length Length of the audio sample
   * @param freq Frequency of the recorded audio sample
   * @param repeat Notification of a repeat-play or single-play sample
   */
  async event void done(void* addr, uint16_t length, bool repeat);

  /**
   * Notification that a sample is repeating.  This event is purely
   * informational.
   */
  async event void repeat(void* addr, uint16_t length);
}
