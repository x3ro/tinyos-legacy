/*
 * Copyright (c) 2004-2005 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */
configuration FNseq {
  provides {
    interface MateBytecode as Map;
    interface MateBytecode as ForEach;
    interface MateBytecode as Vector2List;
    interface MateBytecode as List2Vector;
    interface MateBytecode as String2List;
    interface MateBytecode as List2String;
    interface MateBytecode as Length;
    interface MateBytecode as Memq;
    interface MateBytecode as Memv;
    interface MateBytecode as Assq;
    interface MateBytecode as Assv;
    interface MateBytecode as Reverse;
    interface MateBytecode as Append;
 }
}
implementation {
  components FNseqM, MProxy, MOPcall;

  Map = FNseqM.Map;
  ForEach = FNseqM.ForEach;
  Vector2List = FNseqM.Vector2List;
  List2Vector = FNseqM.List2Vector;
  String2List = FNseqM.String2List;
  List2String = FNseqM.List2String;
  Length = FNseqM.Length;
  Memq = FNseqM.Memq;
  Memv = FNseqM.Memv;
  Assq = FNseqM.Assq;
  Assv = FNseqM.Assv;
  Reverse = FNseqM.Reverse;
  Append = FNseqM.Append;

  FNseqM.GC -> MProxy;
  FNseqM.S -> MProxy;
  FNseqM.T -> MProxy;
  FNseqM.E -> MProxy;
  FNseqM.V -> MProxy;
  FNseqM.Exec -> MOPcall.Exec;
  FNseqM.MapFrame <- MProxy.MotlleFrame[MOTLLE_MAP_FRAME];
  FNseqM.ForeachFrame <- MProxy.MotlleFrame[MOTLLE_FOREACH_FRAME];
}
