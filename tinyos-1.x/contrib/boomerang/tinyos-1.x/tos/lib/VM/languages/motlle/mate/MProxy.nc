/*
 * Copyright (c) 2004-2005 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */
configuration MProxy
{
  provides {
    interface MotlleGC as GC;
    interface MotlleGlobals as G;
    interface MotlleStack as S;
    interface MotlleTypes as T;
    interface MotlleValues as V;
    interface MotlleVar as LV;
    interface MotlleVar as CV;
    interface MotlleVar as RawLV;
    interface MotlleVar as RawCV;
    interface MateError as E;
    interface MotlleCode as C;
  }
  uses interface MotlleFrame[uint8_t kind];
}
implementation {
  components MOPcall, Memory, MotlleRep, MotlleObjects, MErrorProxy,
    MotlleDecoder, MotlleDebug;

  GC = Memory;
  G = Memory;
  S = Memory;
  T = MotlleObjects;
  V = MotlleRep;
  LV = MOPcall.LV;
  CV = MOPcall.CV;
  RawLV = MOPcall.RawLV;
  RawCV = MOPcall.RawCV;
  E = MErrorProxy;
  MotlleFrame = Memory;
  C = MotlleDecoder;
}
