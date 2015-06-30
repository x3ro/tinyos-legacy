/*
 * Copyright (c) 2004-2005 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */
configuration MOPcst {
  provides {
    interface MateBytecode as Cst;
    interface MateBytecode as Int;
    interface MateBytecode as Undefined;
  }
}
implementation {
  components MOPcstM, MProxy;

  Cst = MOPcstM.Cst;
  Int = MOPcstM.Int;
  Undefined = MOPcstM.Undefined;

  MOPcstM.S -> MProxy;
  MOPcstM.C -> MProxy;
  MOPcstM.T -> MProxy;
}
