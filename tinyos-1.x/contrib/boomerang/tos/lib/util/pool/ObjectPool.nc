/*
 * Copyright (c) 2006 Moteiv Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached MOTEIV-LICENSE     
 * file. If you do not find these files, copies can be found at
 * http://www.moteiv.com/MOTEIV-LICENSE.txt and by emailing info@moteiv.com.
 */

/**
 * A generic interface for storing objects into a pool structure.
 *
 * @author Joe Polastre, Moteiv Corporation <info@moteiv.com>
 */
interface ObjectPool<object_type> {

  /**
   * Insert a message into the pool
   *
   * @param obj the object to be inserted
   *
   * @return SUCCESS if the object was inserted into the pool
   */
  command result_t insert(object_type* obj);

  /**
   * Remove a message from the pool
   *
   * @param obj the object to be removed
   *
   * @return SUCCESS if the object was removed the pool
   */
  command result_t remove(object_type* obj);

  /**
   * Get the maximum number of possible entries in the pool
   *
   * @return the number of entries in the pool
   */
  async command uint8_t max();

  /**
   * Get the maximum number of populated entries in the pool
   *
   * @return the number of entries in the pool
   */
  async command uint8_t populated();

  /*
   * Compresses the entries into the first 'n' slots where 'n' is
   * the number of entries that are populated
   */
  //command void compress();

  /**
   * Get the entry at a certain position
   *
   * @param position the position of interest
   *
   * @return a pointer to the object at the specified position
   */
  async command object_type* get(uint8_t position);

  /**
   * Get the first not-NULL element in the pool, or ObjectPool.max otherwise.
   *
   * @return the first not-NULL element in the pool, or max if the pool is empty
   */
  async command uint8_t first();

  async command bool valid( uint8_t n );
  async command uint8_t next( uint8_t n );
}

