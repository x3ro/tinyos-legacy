//$Id: Grenade.nc,v 1.2 2005/07/06 17:25:04 cssharp Exp $
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
 * Interface for Grenade Timer using X1226 Real Timer Clock chip. <p>
 *
 * @modified 5/22/05
 *
 * @author Jaein Jeong
 */

interface Grenade {
  /**
   * Initializes the state of the Grenade timer.
   * It is recommended to call this command before using the Grenade timer.
   *
   * @return SUCCESS if the Grenade timer is successfully initialized.
   */
  command result_t Init();
  /**
   * Sets the alarm for and starts the Grenade timer so that the Grenade
   * timer is triggered after a given interval and resets the sensor node.
   *
   * @param interval_hour time interval in hours to trigger 
   * the grenade Timer
   * @param interval_min time interval in minutes to trigger 
   * the grenade Timer
   * @param interval_sec time interval in seconds to trigger 
   * the grenade Timer
   * @return SUCCESS if the Grenade time is successfully scheduled for
   * trigger.
   */
  command result_t GrenadeArmNow(int8_t interval_hour,
                                 int8_t interval_min,
                                 int8_t interval_sec);

}

