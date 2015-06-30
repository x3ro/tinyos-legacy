/*
 * Copyright (c) 2004-2005 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */
configuration FNreal {
  provides {
    interface MateBytecode as FloatP;
    interface MateBytecode as Truncate;
    interface MateBytecode as Ceiling;
    interface MateBytecode as Floor;
  }
}
implementation {
  components FNrealM, MProxy;

/*
 * Copyright (c) 2004-2005 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */
  FloatP = FNrealM.FloatP;
  Truncate = FNrealM.Truncate;
  Ceiling = FNrealM.Ceiling;
  Floor = FNrealM.Floor;

  FNrealM.S -> MProxy;
  FNrealM.T -> MProxy;
  FNrealM.E -> MProxy;
}
