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
 * Internal interface for SP to talk to link protocols.
 *
 * @author Joe Polastre, Moteiv Corporation <info@moteiv.com>
 */
interface SPLinkEvents {

  /**
   * Notification that the link is active.
   */
  event void active();
  /**
   * Notification that the link is inactive (sleeping).
   */
  event void sleep();

  /**
   * Notification that a neighbor's schedule has expired.
   *
   * @param n Neighbor whose schedule has expired
   */
  event void expired(sp_neighbor_t* n);

}
