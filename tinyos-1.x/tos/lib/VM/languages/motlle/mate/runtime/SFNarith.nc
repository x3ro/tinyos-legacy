/*
 * Copyright (c) 2004-2005 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */
configuration SFNarith {
  provides {
    interface MateBytecode as Nlt;
    interface MateBytecode as Nle;
    interface MateBytecode as Ngt;
    interface MateBytecode as Nge;
    interface MateBytecode as Add;
    interface MateBytecode as Subtract;
    interface MateBytecode as Multiply;
    interface MateBytecode as PositiveP;
    interface MateBytecode as NegativeP;
    interface MateBytecode as ZeroP;
    interface MateBytecode as OddP;
    interface MateBytecode as EvenP;
    interface MateBytecode as Or;
    interface MateBytecode as And;
    interface MateBytecode as Xor;
    interface MateBytecode as Quotient;
    interface MateBytecode as SRemainder;
    interface MateBytecode as Modulo;
  }
}
implementation {
  components SFNarithM, MProxy;

  Nlt = SFNarithM.Nlt;
  Nle = SFNarithM.Nle;
  Ngt = SFNarithM.Ngt;
  Nge = SFNarithM.Nge;
  Add = SFNarithM.Add;
  Subtract = SFNarithM.Subtract;
  Multiply = SFNarithM.Multiply;
  PositiveP = SFNarithM.PositiveP;
  NegativeP = SFNarithM.NegativeP;
  ZeroP = SFNarithM.ZeroP;
  OddP = SFNarithM.OddP;
  EvenP = SFNarithM.EvenP;
  Or = SFNarithM.Or;
  And = SFNarithM.And;
  Xor = SFNarithM.Xor;
  Quotient = SFNarithM.Quotient;
  SRemainder = SFNarithM.SRemainder;
  Modulo = SFNarithM.Modulo;

  SFNarithM.S -> MProxy;
  SFNarithM.T -> MProxy;
  SFNarithM.E -> MProxy;
}
