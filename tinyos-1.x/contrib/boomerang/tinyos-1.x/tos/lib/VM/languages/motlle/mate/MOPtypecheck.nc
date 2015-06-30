/*
 * Copyright (c) 2004-2005 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */
configuration MOPtypecheck {
  provides {
    interface MateBytecode as StackCheck;
    interface MateBytecode as VarCheck;
  }
}
implementation {
  components MOPtypecheckM, MProxy;

  StackCheck = MOPtypecheckM.StackCheck;
  VarCheck = MOPtypecheckM.VarCheck;
  MOPtypecheckM.C -> MProxy;
  MOPtypecheckM.S -> MProxy;
  MOPtypecheckM.T -> MProxy;
  MOPtypecheckM.E -> MProxy;
  MOPtypecheckM.LV -> MProxy.LV;
}
