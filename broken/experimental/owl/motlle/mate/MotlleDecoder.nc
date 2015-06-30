configuration MotlleDecoder {
  provides interface MotlleCode as C;
}
implementation {
  components MotlleDecoderM, MProxy;

  C = MotlleDecoderM;
  MotlleDecoderM.V -> MProxy;
  MotlleDecoderM.GC -> MProxy;
}
