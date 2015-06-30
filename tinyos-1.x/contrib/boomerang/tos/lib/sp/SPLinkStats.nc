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
interface SPLinkStats {

  /**
   * Get the state of the radio, as defined by the type
   * sp_linkstate_t
   */
  command sp_linkstate_t getState();

  /**
   * Instruct the link to find new neighbors
   */
  command result_t find();

  /**
   * Notify the link to stop finding new neighbors
   */
  command result_t findDone();

  /**
   * Update the link quality for a specific neighbor based on the
   * packet passed into this function
   */
  command uint16_t getQuality(sp_neighbor_t* n, TOS_Msg* msg);

}
