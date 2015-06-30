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
 * Shared variables that operate within a one-hop radio neighborhood.
 */
configuration SharedVarOneHop {
  provides {
    interface SharedVar[uint8_t key];
  }
} implementation {

  components Main, SharedVarOneHopM, GenericComm as Comm, QueuedSend;

  SharedVar = SharedVarOneHopM;

  Main.StdControl -> SharedVarOneHopM;
  Main.StdControl -> Comm;
  SharedVarOneHopM.SendMsg -> QueuedSend.SendMsg[AM_SHAREDVARMSG];
  SharedVarOneHopM.ReceiveMsg -> Comm.ReceiveMsg[AM_SHAREDVARMSG];

} 
