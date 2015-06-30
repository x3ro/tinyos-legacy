/*
 * Copyright (c) 2004-2005 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */
configuration MStacksProxy {
  provides {
    interface MateStacks;
  }
}
implementation {
  components MateEmulation, MProxy;

  MateStacks = MateEmulation;
  MateEmulation.V -> MProxy;
  MateEmulation.S -> MProxy;
  MateEmulation.T -> MProxy;
  MateEmulation.E -> MProxy;
}
