/*
 * Copyright (c) 2006 Moteiv Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached MOTEIV-LICENSE     
 * file. If you do not find these files, copies can be found at
 * http://www.moteiv.com/MOTEIV-LICENSE.txt and by emailing info@moteiv.com.
 */

/**
 * Implementation of generic advanced button gestures.  Requires
 * an underlying button object for the basic events.
 *
 * @author Joe Polastre, Moteiv Corporation <info@moteiv.com>
 */
generic module ButtonAdvancedM() {
  provides interface ButtonAdvanced;
  uses {
    interface Button;
    interface Timer2<TMilli> as Timer;
  }
}
implementation {

  uint8_t m_count;
  uint32_t m_press;
  norace uint16_t m_longpress = 1152; // all 16-bit atomic ops

  enum {
    TIME_DELAY = 250,
  };

  async command void ButtonAdvanced.enable() {
    call Button.enable();
  }

  async command void ButtonAdvanced.disable() {
    call Button.disable();
  }

  async command void ButtonAdvanced.setLongPress(uint16_t time) {
    m_longpress = time;
  }

  async command uint16_t ButtonAdvanced.getLongPress() {
    return m_longpress;
  }

  async event void Button.pressed(uint32_t time) {
    m_press = time;
  }

  task void startTimer() {
      call Timer.startOneShot( TIME_DELAY );
  }

  async event void Button.released(uint32_t time) {
    if (time - m_press > (uint32_t)m_longpress) {
      signal ButtonAdvanced.longClick(time - m_press);
    }
    else {
      m_count++;
      post startTimer();
    }
  }

  event void Timer.fired() {
    uint8_t _count;
    atomic {
      _count = m_count;
      m_count = 0;
    }
    signal ButtonAdvanced.multiClick(_count);
  }

}
