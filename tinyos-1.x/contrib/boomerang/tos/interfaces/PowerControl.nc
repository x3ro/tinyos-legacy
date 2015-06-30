/*
 * Copyright (c) 2006 Moteiv Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached MOTEIV-LICENSE     
 * file. If you do not find these files, copies can be found at
 * http://www.moteiv.com/MOTEIV-LICENSE.txt and by emailing info@moteiv.com.
 */

/**
 * Interface for starting and stopping components that are under
 * automatic shutdown for power management purposes.  Using PowerControl
 * can wake the component out of its shutdown state.  If the system is
 * already running and start() is called, a startDone() event will be
 * signalled immediately.  The same semantic is true for stop() and stopDone().
 *
 * @author Joe Polastre, Moteiv Corporation <info@moteiv.com>
 * @author Cory Sharp, Moteiv Corporation <cory@moteiv.com>
 */
interface PowerControl {
  /**
   * Start the subsystem.  A started event will occur later.
   *
   * @return SUCCESS if the system is now starting or is already running, FAIL
   * if the subsystem will not start.
   */
  command result_t start();

  /**
   * The subsystem is now started.  This event is signalled any time the system
   * is started from a stop state.
   */
  event void started();

  /**
   * Request the subsystem to stop.  This is only a request,
   * PowerKeepAlive.shutdown is signaled, and the subsystem remains awake if a
   * component calls PowerKeepAlive.keepAlive.
   *
   * @return SUCCESS if the subsystem is going to shutdown, FAIL if the
   * subsystem is going to stay awake.
   */
  command result_t stop();

  /**
   * The subsystem is now stopped.  This event is signalled any time the system
   * is stopped from a start state.
   */
  event void stopped();
}

