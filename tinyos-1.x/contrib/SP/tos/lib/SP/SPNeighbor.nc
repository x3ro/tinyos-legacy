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
 * @modified 3/8/06
 *
 * @author Arsalan Tavakoli <arsalan@cs.berkeley.edu>
 * @author Sukun Kim <binetude@cs.berkeley.edu>
 * @author Joe Polastre <joe@polastre.com>
 */
#include "SP.h"
interface SPNeighbor {
  /*
   * Inserts a neighbor into the table
   *
   * @param neighbor - The entry to be inserted into the
   *   neighbor table
   * @param msg - The packet that can be used to fill in
   *   the link layer address portion of the entry
   *
   * @result - Returns SP Handle of inserted node.  It is
   *   set as TOS_NO_HANDLE if insert fails.
   *
   * NOTE: If neighbor already exists, its information is
   *  updated using the new entry
   */
   command uint8_t insert(sp_neighbor_t* neighbor, TOS_MsgPtr msg);

  /*
   * Gets a pointer to a SP Neighbor table entry
   *
   * @param msg - A message from the node for which the requested
   *   entry will be used.
   *
   * @result - Returns NULL if no space is available AND if the node
   *   is already in the table. (Should this change)
   */
   command sp_neighbor_t* getPointer(TOS_MsgPtr msg);

  /*
   * Remove a neighbor from the table
   *
   * @param neighbor - Entry to be removed
   *
   * @result - SUCCESS if entry exists and was removed
   */
   command result_t remove(sp_neighbor_t* neighbor);

  /*
   * Tell SP to make sure radio is on during neighbor's
   *  next active period
   *
   * @param neighbor - Neighbor to listen to
   *
   * @result - SUCCESS if neighbor has a valid next
   *   activity period
   */
   command result_t listen(sp_neighbor_t* neighbor);
   
  /*
   * Adjust the link estimate of a neighbor
   *
   * @param neighbor - Entry for the neighbor whose quality
   *   should be updated
   * @param msg - Packet that contains the lqi value
   *
   * @result - SUCCESS if quality updated
   */
   command result_t adjust(sp_neighbor_t* neighbor, TOS_MsgPtr msg);

  /*
   * Have SP instruct MAC layer to search for neighbors
   */
   command result_t find();

  /*
   * Have SP instruct MAC layer to stop search for neighbors
   */
   command result_t findDone();
   
  /*
   * Retrieve a certain neighbor table entry
   *
   * @param handle - SP-handle of desired neighbor entry
   *
   * @result - NULL if neighbor doesn't exist
   */
   command sp_neighbor_t* get(uint8_t sp_handle);

  /*
   * Returns the maximum number of neighbors
   */
   command uint8_t max_neighbors();
   
  /*
   * Event signalled to allow network protocols to vote
   *  on the admittance of a new neighbor
   *
   * @param neighbor - New entry to admit
   *
   * @result - TRUE indicates entry should be admitted
   */
   event result_t admit(sp_neighbor_t* neighbor);

  /*
   * Notification that a neighbor is being evicted from the
   *  table
   *
   * @param neighbor - Entry for neighbor that is being
   *   evicted.  Pointer is valid only until function
   *   returns.
   */
   event void evicted(sp_neighbor_t* neighbor);

  /*
   * Notification that a neighbor's active period
   *  information has expired.
   *
   * @param neighbor - Entry for neighbor that has expired
   * @param timeon - Start of neighbor's last known active
   *   period
   * @param timeoff - End of neighbor's last known active
   *   period
   */
   event void expired(sp_neighbor_t* neighbor, uint32_t timeon, uint32_t timeoff);
}
