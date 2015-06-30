/*
 * Copyright (c) 2004-2005 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */
configuration SFNmagic {
  provides {
    //FN =: x1 x2 -> b. True if x1 and x2 are equal
    interface MateBytecode as NumeqP;

    //FN eq?: x1 x2 -> b. True if x1 and x2 are the same object
    interface MateBytecode as EqP;

    //FN eqv?: x1 x2 -> b. True if x1 and x2 are the same object
    interface MateBytecode as EqvP;

    //FN any-ref: x1 n -> x2. Lookup nth element of vector or string x1
    interface MateBytecode as AnyRef;

    //FN vector-ref: v1 n -> x2. Lookup nth element of vector v1
    interface MateBytecode as VectorRef;

    //FN string-ref: s1 n -> x2. Lookup nth element of s1
    interface MateBytecode as StringRef;

    //FN any-set!: x1 n x2 -> x2. Set nth element of vector or string x1 to x2
    interface MateBytecode as AnySetB;

    //FN vector-set!: v1 n x2 -> x2. Set nth element of vector v1 to x2
    interface MateBytecode as VectorSetB;

    //FN string-set!: s1 n x2 -> x2. Set nth element of s1 to x2
    interface MateBytecode as StringSetB;

    //FN not: b1 -> b2. Return logical negation of b1
    interface MateBytecode as Not;
  }
}
implementation {
  components OPmeq, OPmref, OPmset, OPmnot;

  NumeqP = OPmeq;
  EqP = OPmeq;
  EqvP = OPmeq;

  AnyRef = OPmref;
  StringRef = OPmref;
  VectorRef = OPmref;

  AnySetB = OPmset;
  VectorSetB = OPmset;
  StringSetB = OPmset;

  Not = OPmnot;
}
