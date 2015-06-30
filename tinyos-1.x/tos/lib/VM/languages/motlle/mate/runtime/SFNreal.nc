/*
 * Copyright (c) 2004-2005 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */
configuration SFNreal {
  provides interface MateBytecode as Divide;
}
implementation {
  components SFNrealM, MProxy;

  Divide = SFNrealM.Divide;

  SFNrealM.S -> MProxy;
  SFNrealM.T -> MProxy;
  SFNrealM.E -> MProxy;
}
