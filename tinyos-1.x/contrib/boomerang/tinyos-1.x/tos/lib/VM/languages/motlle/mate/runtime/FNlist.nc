/*
 * Copyright (c) 2004-2005 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */
configuration FNlist {
  provides {
    interface MateBytecode as Cons;
    interface MateBytecode as PairP;
    interface MateBytecode as ListP;
    interface MateBytecode as NullP;
    interface MateBytecode as SetCarB;
    interface MateBytecode as SetCdrB;
    interface MateBytecode as List;
    interface MateBytecode as ListTail;
    interface MateBytecode as ListRef;
    interface MateBytecode as Car;
    interface MateBytecode as Cdr;
    interface MateBytecode as Caar;
    interface MateBytecode as Cadr;
    interface MateBytecode as Cdar;
    interface MateBytecode as Cddr;
    interface MateBytecode as Caaar;
    interface MateBytecode as Caadr;
    interface MateBytecode as Cadar;
    interface MateBytecode as Caddr;
    interface MateBytecode as Cdaar;
    interface MateBytecode as Cdadr;
    interface MateBytecode as Cddar;
    interface MateBytecode as Cdddr;
  }
}
implementation {
  components FNlistM, MProxy;

  Cons = FNlistM.Cons;
  PairP = FNlistM.PairP;
  ListP = FNlistM.ListP;
  NullP = FNlistM.NullP;
  SetCarB = FNlistM.SetCarB;
  SetCdrB = FNlistM.SetCdrB;
  List = FNlistM.List;
  ListTail = FNlistM.ListTail;
  ListRef = FNlistM.ListRef;
  Car = FNlistM.Car;
  Cdr = FNlistM.Cdr;
  Caar = FNlistM.Caar;
  Cadr = FNlistM.Cadr;
  Cdar = FNlistM.Cdar;
  Cddr = FNlistM.Cddr;
  Caaar = FNlistM.Caaar;
  Caadr = FNlistM.Caadr;
  Cadar = FNlistM.Cadar;
  Caddr = FNlistM.Caddr;
  Cdaar = FNlistM.Cdaar;
  Cdadr = FNlistM.Cdadr;
  Cddar = FNlistM.Cddar;
  Cdddr = FNlistM.Cdddr;

  FNlistM.S -> MProxy;
  FNlistM.T -> MProxy;
  FNlistM.E -> MProxy;
  FNlistM.V -> MProxy;
  FNlistM.GC -> MProxy;
}
