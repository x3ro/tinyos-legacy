// $Id: TimerExclusive.nc,v 1.1.1.1 2007/11/05 19:11:34 jpolastre Exp $
/*
 * Copyright (c) 2005 Moteiv Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached MOTEIV-LICENSE     
 * file. If you do not find these files, copies can be found at
 * http://www.moteiv.com/MOTEIV-LICENSE.txt and by emailing info@moteiv.com.
 */
interface TimerExclusive {
  /**
   * Prepare Timer to be set with an interval, cs, and cd
   */
  async command result_t prepareTimer(uint8_t rh, uint16_t interval, uint16_t csSAMPCON, uint16_t cdSAMPCON);
  /**
   * Start Timer
   */
  async command result_t startTimer(uint8_t rh);
  /**
   * Stop Timer
   */
  async command result_t stopTimer(uint8_t rh);

}
