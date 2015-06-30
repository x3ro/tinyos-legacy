/*
 * Copyright (c) 2004-2005 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */
configuration MOPcontrol {
  provides {
    interface MateBytecode as Branch;
    interface MateBytecode as BranchIfFalse;
    interface MateBytecode as BranchIfTrue;
  }
}
implementation {
  components MOPcontrolM, MProxy;

  Branch = MOPcontrolM.Branch;
  BranchIfTrue = MOPcontrolM.BranchIfTrue;
  BranchIfFalse = MOPcontrolM.BranchIfFalse;

  MOPcontrolM.T -> MProxy;
  MOPcontrolM.S -> MProxy;
  MOPcontrolM.V -> MProxy;
  MOPcontrolM.C -> MProxy;
}
