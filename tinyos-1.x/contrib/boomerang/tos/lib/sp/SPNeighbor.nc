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
 * Manage entries in the SP neighbor table.
 *
 * @author Joe Polastre, Moteiv Corporation <info@moteiv.com>
 */
interface SPNeighbor
{
  /**
   * Get the neighbor at position i.
   */
  async command sp_neighbor_t* get( uint8_t n );

  /**
   * Get the maximum number of entries in the table.
   */
  async command uint8_t max();

  async command uint8_t first();
  async command bool valid( uint8_t n );
  async command uint8_t next( uint8_t n );
  async command uint8_t populated();

  /**
   * Insert a new neighbor to the table.  If the neighbor is already
   * in the table, its values are refreshed and the 'update' event
   * is signalled to all other services.
   */
  command result_t insert(sp_neighbor_t* neighbor);
  /**
   * Remove a neighbor from the neighbor table.  You can only remove
   * a neighbor if you put it into the neighbor table (if you are the
   * owner).
   */
  command result_t remove(sp_neighbor_t* neighbor);
  /**
   * Notify SP that the contents of a neighbor table entry have changed.
   * Any service can change the contents of a neighbor table entry.
   * All other SPNeighbor services are notified of the change through
   * the update() event.
   * <p>
   * <b>WARNING:</b> Do not modify/change a neighbor entry when
   * the neighbor is currently active.  Always check the
   * <tt>SP_FLAG_LINK_ACTIVE</tt> flag before performing any
   * modifications.  If the link is active, wait until the expiration
   * event before performing schedule modifications.  Failure to 
   * heed this warning may result in unpredictable operation.
   */
  command void change(sp_neighbor_t* neighbor);
  /**
   * Notification than an entry has been updated ("changed").
   */
  event void update(sp_neighbor_t* neighbor);
  /**
   * Query from SP to user services asking if the specified neighbor
   * should be admitted to the SP Neighbor Table.
   *
   * @return SUCCESS to admit the neighbor to the neighbor table.
   */
  event result_t admit(sp_neighbor_t* neighbor);

  /**
   * Notification that a neighbor's schedule has expired.
   * Only the service that owns the neighbor is notified.
   * If multiple schedules are desired, multiple sp_neighbor_t entries
   * should be inserted into the table.  By only notifying the
   * service that set the schedule, SP is providing a minimal amount
   * of protection.  SP takes care of computing the union of all schedules
   * for a particular neighbor.
   * <p>
   * Update the schedule and then call the 'change()' command
   * to notify SP of the updated schedule.
   */
  event void expired(sp_neighbor_t* neighbor);
  /**
   * The neighbor was evicted by another process/task.
   */
  event void evicted(sp_neighbor_t* neighbor);

  /**
   * Get the flags associated with this entry.
   * Flags are READ-ONLY.
   * <p>
   * Flags are:<br>
   * <pre>
   *  SP_FLAG_TABLE   -- the entry is in the neighbor table
   *  SP_FLAG_BUSY    -- the entry is currently busy
   *  SP_FLAG_LISTEN  -- the listen bit is set
   *  SP_FLAG_LINK_ACTIVE -- the link is currently on/active
   * </pre>
   */
  command sp_neighbor_flags_t getFlags(sp_neighbor_t* neighbor);

  /**
   * Try to find more neighbors.  All find commands must have
   * a corresponding findDone command following it.  find commands
   * are reference counted, so make sure that nested finds also
   * have the appropriate un-nesting of findDone commands.
   */
  command result_t find();
  /**
   * Stop finding new neighbors.
   */
  command result_t findDone();
}
