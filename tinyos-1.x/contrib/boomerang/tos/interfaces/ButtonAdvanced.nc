/*
 * Copyright (c) 2006 Moteiv Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached MOTEIV-LICENSE     
 * file. If you do not find these files, copies can be found at
 * http://www.moteiv.com/MOTEIV-LICENSE.txt and by emailing info@moteiv.com.
 */

/**
 * Advanced button handling interface for complex gestures.
 *
 * @author Joe Polastre, Moteiv Corporation <info@moteiv.com>
 */
interface ButtonAdvanced {

  /**
   * Enable advanced button processing.
   */
  async command void enable();
  /**
   * Disable advanced button processing.
   */
  async command void disable();
  /**
   * Request events when a long press occurs.
   *
   * @param time the number of milliseconds in duration for a button press
   */
  async command void setLongPress(uint16_t time);
  /**
   * Get the time requested for a long button press.
   *
   * @return time the time required for a long press in milliseconds
   */
  async command uint16_t getLongPress();

  /**
   * Notification that a long click occurred.
   *
   * @param time The time that the long click started
   */
  async event void longClick(uint32_t time);
  /**
   * Notification that multiple clicks occurred.
   *
   * @param count Number of clicks in the multi click event
   */
  async event void multiClick(uint8_t count);
}
