// $Id: GlobalTime.nc,v 1.1.1.1 2007/11/05 19:11:29 jpolastre Exp $
/*
 * Copyright (c) 2006 Moteiv Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached MOTEIV-LICENSE     
 * file. If you do not find these files, copies can be found at
 * http://www.moteiv.com/MOTEIV-LICENSE.txt and by emailing info@moteiv.com.
 */

#include "Timer2.h"
#include "GlobalTime.h"

/**
 * Acquisition of a global time source with a given precision.
 * 
 * @param precision_tag The precision of the time source, ie T32khz or TMilli
 *
 * @author Joe Polastre, Moteiv Corporation <info@moteiv.com>
 */
interface GlobalTime<precision_tag>
{
  /**
   * Get the current global time value.
   *
   * @return a 32-bit value with the units of precision_tag
   */
  async command uint32_t get();

  /**
   * Get both the global and local time at the same instance (prevents
   * calling both LocalTime and GlobalTime in sequence, and having
   * inaccuracies in timing calculations).
   *
   * @return A struct (global_time_t) returning both the global time
   *         accessible through <tt>.global</tt> and the local time accessible
   *         through <tt>.local</tt>
   */
  async command global_time_t getBoth();

  /**
   * Converts a local time to the global time.
   *
   * @param local The local time to convert to global time
   * @return Global time value
   */
  async command uint32_t convertToGlobal(uint32_t local);

  /**
   * Converts a global time to the local time.
   *
   * @param local The global time to convert to local time
   * @return Local time value
   */
  async command uint32_t convertToLocal(uint32_t global);

  /**
   * Notifies the caller if the global time has been established.
   *
   * @return TRUE if the time is valid, FALSE if no time has been established
   *         globally by this node.
   */
  async command bool isValid();
}

