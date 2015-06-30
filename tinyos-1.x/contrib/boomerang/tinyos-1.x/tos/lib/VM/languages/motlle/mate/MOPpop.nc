/*
 * Copyright (c) 2004-2005 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */
configuration MOPpop {
  provides {
    interface MateBytecode as Pop;
    interface MateBytecode as ExitN;
  }
}
implementation {
  components MOPpopM, MProxy;

  Pop = MOPpopM.Pop;
  ExitN = MOPpopM.ExitN;
  MOPpopM.S -> MProxy;
  MOPpopM.C -> MProxy;
}
