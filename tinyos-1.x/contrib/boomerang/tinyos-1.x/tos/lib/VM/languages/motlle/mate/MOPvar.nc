/*
 * Copyright (c) 2004-2005 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */
configuration MOPvar {
  provides {
    interface MateBytecode as ReadLocal;
    interface MateBytecode as ReadLocal3;
    interface MateBytecode as ReadGlobal;
    interface MateBytecode as ReadClosure;
    interface MateBytecode as ReadClosure3;
    interface MateBytecode as WriteLocal;
    interface MateBytecode as WriteLocal3;
    interface MateBytecode as WriteGlobal;
    interface MateBytecode as WriteClosure;
    interface MateBytecode as WriteDiscardLocal;
    interface MateBytecode as WriteDiscardLocal3;
    interface MateBytecode as WriteDiscardGlobal;
    interface MateBytecode as WriteDiscardClosure;
    interface MateBytecode as ClearLocal;
  }
}
implementation {
  components MOPvarM, MProxy;

  ReadLocal = MOPvarM.ReadLocal;
  ReadLocal3 = MOPvarM.ReadLocal3;
  WriteLocal = MOPvarM.WriteLocal;
  WriteLocal3 = MOPvarM.WriteLocal3;
  ReadGlobal = MOPvarM.ReadGlobal;
  WriteGlobal = MOPvarM.WriteGlobal;
  ReadClosure = MOPvarM.ReadClosure;
  ReadClosure3 = MOPvarM.ReadClosure3;
  WriteClosure = MOPvarM.WriteClosure;
  ClearLocal = MOPvarM.ClearLocal;
  WriteDiscardLocal = MOPvarM.WriteDiscardLocal;
  WriteDiscardLocal3 = MOPvarM.WriteDiscardLocal3;
  WriteDiscardGlobal = MOPvarM.WriteDiscardGlobal;
  WriteDiscardClosure = MOPvarM.WriteDiscardClosure;

  MOPvarM.T -> MProxy;
  MOPvarM.S -> MProxy;
  MOPvarM.G -> MProxy;
  MOPvarM.LV -> MProxy.LV;
  MOPvarM.CV -> MProxy.CV;
  MOPvarM.C -> MProxy;
}
