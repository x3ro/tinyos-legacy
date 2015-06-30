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

includes SharedVar;

/**
 * Interface for remote access to "shared variables". A shared variable 
 * is published by a node using put(), and may be retrieved by other nodes 
 * using get(). Remote nodes may not update the value of a shared variable
 * (not through this interface, anyway).
 */
interface SharedVar {

  command result_t get(uint16_t moteaddr, void *buf, int buflen);
  event void getDone(uint16_t moteaddr, void *buf, int buflen, result_t success);
  command result_t put(void *buf, int buflen);

}

