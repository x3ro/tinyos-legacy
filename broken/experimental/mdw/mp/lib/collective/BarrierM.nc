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

includes Collective;

module BarrierM { 
  provides {
    interface Barrier;
  }
} implementation {

  command result_t Barrier.barrier() {
    // XXX Not implemented
    dbg(DBG_USR2, "Barrier.barrier() called.\n");
    signal Barrier.barrierDone();
    return SUCCESS;
  }


}

