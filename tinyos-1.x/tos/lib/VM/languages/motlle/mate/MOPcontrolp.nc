/*
 * Copyright (c) 2004-2005 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */
configuration MOPcontrolp {
  provides {
    interface MateBytecode as BranchIfFalsePreserve;
    interface MateBytecode as BranchIfTruePreserve;
  }
}
implementation {
  components MOPcontrolpM, MProxy;

  BranchIfFalsePreserve = MOPcontrolpM.BranchIfFalsePreserve;
  BranchIfTruePreserve = MOPcontrolpM.BranchIfTruePreserve;

  MOPcontrolpM.T -> MProxy;
  MOPcontrolpM.S -> MProxy;
  MOPcontrolpM.V -> MProxy;
  MOPcontrolpM.C -> MProxy;
}
