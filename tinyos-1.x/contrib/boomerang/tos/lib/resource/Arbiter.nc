// $Id: Arbiter.nc,v 1.1.1.1 2007/11/05 19:11:27 jpolastre Exp $
/*
 * Copyright (c) 2005 Moteiv Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached MOTEIV-LICENSE     
 * file. If you do not find these files, copies can be found at
 * http://www.moteiv.com/MOTEIV-LICENSE.txt and by emailing info@moteiv.com.
 */

/**
 * Please refer to TEP 108 for more information about this interface and its
 * intended use.
 * <p>
 * The Arbiter interface allows a component to query the current 
 * status of an arbiter.  It must be provided by ALL arbiter implementations,
 * and can be used for a variety of different purposes.  Normally it will be
 * used in conjunction with the Resource interface for performing run time
 * checks on access rights to a particular shared resource.
 * <p>
 * Loosely based on the proposal from TEP 108 and TOS2 with some minor
 * modifications, namely:<br>
 * ArbiterInfo (TEP 108) and Arbiter are synonomous<br>
 * requested() and idle() are part of the Arbiter interface instead of
 * ResourceController.<br>
 * userId in TEP 108 is called user in the Arbiter interface.
 *
 * @author Cory Sharp, Moteiv Corporation <info@moteiv.com>
 * @author Kevin Klues (klueska@cs.wustl.edu)
 */
interface Arbiter
{
  /**
   * Check whether a resource is currently allocated.
   *
   * @return TRUE If the resource being arbitrated is currently allocated
   *              to any of its users<br>
   *         FALSE Otherwise.
   */
  async command bool inUse();
  /**
   * Get the id of the client currently using a resource.
   * 
   * @return Id of the current owner of the resource<br>
   *         RESOURCE_NONE if no one currently owns the resource
   */
  async command uint8_t user();
  /**
   * This event is signalled whenever the user of this arbiter
   * currently has control of the resource, and another user requests
   * it.  You may want to consider releasing a resource based on this
   * event.
   */
  async event void requested();
  /**
   * Event sent whenever a resource goes idle.
   * That is to say, whenever no one currently owns the resource, and there
   * are no more pending requests.
   */
  async event void idle();
}

