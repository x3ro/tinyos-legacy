/*
 * Copyright (c) 2006 Moteiv Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached MOTEIV-LICENSE     
 * file. If you do not find these files, copies can be found at
 * http://www.moteiv.com/MOTEIV-LICENSE.txt and by emailing info@moteiv.com.
 */

/**
 * Interface for detecting if a connection has been made with an
 * external entity, such as a bus, device, or sensor.
 *
 * @author Joe Polastre, Moteiv Corporation <info@moteiv.com>
 */
interface Detect {

  /**
   * Query to determine if the device is connected
   *
   * @return TRUE if connected
   */
  command bool isConnected();

  /**
   * Notification that the interface is now connected
   */
  event void connected();

  /**
   * Notification that the interface has been disconnected
   */
  event void disconnected();
}
