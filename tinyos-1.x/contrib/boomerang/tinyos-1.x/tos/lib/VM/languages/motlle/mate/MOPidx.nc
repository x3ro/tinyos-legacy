/*
 * Copyright (c) 2004-2005 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */
configuration MOPidx {
  provides {
    interface MateBytecode as Set;
    interface MateBytecode as Ref;
  }
}
implementation {
  components MOPidxM, MProxy;

  Ref = MOPidxM.Ref;
  Set = MOPidxM.Set;

  MOPidxM.S -> MProxy;
  MOPidxM.V -> MProxy;
  MOPidxM.T -> MProxy;
  MOPidxM.E -> MProxy;
  MOPidxM.GC -> MProxy;
}
