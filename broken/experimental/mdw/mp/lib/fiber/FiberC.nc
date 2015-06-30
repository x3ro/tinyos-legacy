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
 * Fiber: Provides cooperative "threading" support for TinyOS. A 
 * fiber consists of a stack and a private register file; mechanisms 
 * are provided to allow fibers to block waiting for an event to occur.
 */

configuration FiberC {
  provides interface Fiber;
} implementation {
  components Main, FiberM; 

  Fiber = FiberM;
  Main.StdControl -> FiberM.StdControl;
}
