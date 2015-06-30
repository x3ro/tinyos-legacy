/*
 * Copyright (c) 2006 Moteiv Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached MOTEIV-LICENSE     
 * file. If you do not find these files, copies can be found at
 * http://www.moteiv.com/MOTEIV-LICENSE.txt and by emailing info@moteiv.com.
 */

#include "sp.h"

/**
 * Interface for querying the devices (radio interfaces) connected
 * to SP.
 *
 * @author Joe Polastre, Moteiv Corporation <info@moteiv.com>
 */
interface SPInterface {

  /**
   * Check if an interface is a UART link.
   *
   * @param i the interface to check
   *
   * @return TRUE if the link is a UART link.
   */
  command bool isUart(sp_interface_t i);
  /**
   * Check if an interface is a wireless link.
   *
   * @param i the interface to check
   *
   * @return TRUE if the link is a wireless link.
   */
  command bool isWireless(sp_interface_t i);
  /**
   * Check if an interface is a wired link.
   *
   * @param i the interface to check
   *
   * @return TRUE if the link is a wired link.
   */
  command bool isWired(sp_interface_t i);
  /**
   * Get the number of available SP interfaces.
   *
   * @return the count of available interfaces.
   */
  command sp_interface_t getMaxInterfaces();

}
