/*
 * Copyright (c) 2004-2005 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */
configuration OPmhandler {
  provides interface MateBytecode;
  provides interface MateBytecodeLock;
}
implementation {
  components MOPhandlerM, MOPcall, MProxy;

  MateBytecode = MOPhandlerM.ExecHandler;
  MateBytecodeLock = MOPhandlerM.ExecHandlerLocks;

  MOPhandlerM.Exec -> MOPcall.Exec;
  MOPhandlerM.G -> MProxy;
  MOPhandlerM.GC -> MProxy;
  MOPhandlerM.S -> MProxy;
  MOPhandlerM.T -> MProxy;
}
