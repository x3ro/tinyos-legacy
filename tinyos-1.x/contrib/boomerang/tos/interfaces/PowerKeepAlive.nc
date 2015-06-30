/*
 * Copyright (c) 2006 Moteiv Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached MOTEIV-LICENSE     
 * file. If you do not find these files, copies can be found at
 * http://www.moteiv.com/MOTEIV-LICENSE.txt and by emailing info@moteiv.com.
 */

/**
 * Interface for components that implement an automatic shutdown
 * power management policy.  Services are signalled with the shutdown
 * event before entering a low power state.  If a service immediately
 * calls the keepAlive command, the component will remain awake.
 *
 * @author Joe Polastre, Moteiv Corporation <info@moteiv.com>
 * @author Cory Sharp, Moteiv Corporation <info@moteiv.com>
 */
interface PowerKeepAlive {
  /**
   * Query the subsystem to determine if it is alive.
   *
   * @return TRUE if the system is alive, FALSE otherwise.
   */
  async command bool isAlive();

  /**
   * Instruct the subsystem to remain awake through the keep alive event.
   *
   * @return SUCCESS if the system has remained awake or if the system will
   *         start due to the keep alive command. FAIL if the system
   *         has already shut down or if the request cannot be satisfied
   *         at this time.
   */
  command result_t keepAlive();

  /**
   * Notification that the subsystem is about to be shutdown.  When
   * receiving a shutdown event, the subsystem may be kept alive through
   * the keepalive command.  This command must be called within the
   * shutdown() event.
   */
  event void shutdown();
}

