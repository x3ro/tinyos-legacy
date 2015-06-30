/*
 * Copyright (c) 2004-2005 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */
configuration FNstring {
  provides {
    interface MateBytecode as StringP;
    interface MateBytecode as String;
    interface MateBytecode as MakeString;
    interface MateBytecode as StringLength;
    interface MateBytecode as StringFillB;
  }
}
implementation {
  components FNstringM, MProxy;

  StringP = FNstringM.StringP;
  String = FNstringM.String;
  MakeString = FNstringM.MakeString;
  StringLength = FNstringM.StringLength;
  StringFillB = FNstringM.StringFillB;

  FNstringM.S -> MProxy;
  FNstringM.T -> MProxy;
  FNstringM.E -> MProxy;
}
