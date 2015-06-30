/*
 * Copyright (c) 2006 Moteiv Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached MOTEIV-LICENSE     
 * file. If you do not find these files, copies can be found at
 * http://www.moteiv.com/MOTEIV-LICENSE.txt and by emailing info@moteiv.com.
 */

/**
 * Spram ("SP RAM") interface for disseminating data across a sensor network.
 *
 * @author Cory Sharp, Moteiv Corporation <info@moteiv.com>
 */
interface Spram {
  /**
   * Get a pointer to Spram's data buffer.
   */
  async command void* getData();
  /**
   * Get the size of Spram's data buffer.
   */
  command uint16_t getSizeBytes();
  /** 
   * Publish new data with the specified size.
   */
  command void publish( uint16_t bytes );
  /**
   * Notification that the data buffer is now locked by Spram.
   */
  event void locked();
  /**
   * Notification that the data buffer is now unlocked.
   */
  event void updated();

  /**
   * Query if the data in the data buffer is valid.
   */
  command bool isValid();
  /**
   * Query if the data buffer is currently locked by another process.
   */
  command bool isLocked();
  /**
   * Lock the data buffer.
   *
   * @return SUCCESS if the buffer can be locked; FAIL if it is already locked.
   */
  command result_t lock();
  /**
   * Invalidate the data in Spram's buffer.  Forces a new fetch.
   */
  command void invalidate();
}

