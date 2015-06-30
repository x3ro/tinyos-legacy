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
