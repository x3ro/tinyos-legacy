/* Copyright (c) 2002 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704. Attention: Intel License Inquiry.  
 * 
 * Author: Matt Welsh <mdw@eecs.harvard.edu>
 */

/** 
 * Blocking SharedVar interface.
 */

interface NCSSharedVar {

  /**
   * Get the variable value from mote 'moteaddr' into 'buf' with size
   * 'buflen'. If timeout is 0, initiate the get but do not wait for the
   * buffer to be filled; a call to sync() will block until all pending
   * get() calls complete. If timeout is nonzero, wait for 'timeout' ms.
   * Returns SUCCESS if the get was accomplished or initiated, FAIL
   * otherwise.
   */
  command result_t get(uint16_t moteaddr, void *buf, int buflen, int timeout);

  /**
   * Wait for all pending get() requests to complete, for up to 'timeout'
   * milliseconds.
   */
  command result_t sync(int timeout);

  /**
   * Set the local value of the shared variable.
   */
  command void set(void *buf, int buflen);

}
