module MotlleDecoderM {
  provides interface MotlleCode as C;
  uses {
    interface MotlleValues as V;
    interface MotlleGC as GC;
  }
}
implementation {
  MINLINE uint8_t b(MateContext *context) {
    uint16_t pc = context->pc;

    context->pc++;
    return (call GC.base())[pc];
  }

  MINLINE command uint8_t C.read_uint8_t(MateContext *context) {
    return b(context);
  }

  MINLINE command int16_t C.read_offset(MateContext *context, bool sixteen) {
    uint8_t b1 = b(context);

    // offsets are big-endian
    if (sixteen)
      return b1 << 8 | b(context);
    else
      return (int8_t)b1;
  }

  MINLINE command uint16_t C.read_local_var(MateContext *context) {
    return b(context);
  }
    
  MINLINE command uint16_t C.read_closure_var(MateContext *context) {
    return b(context);
  }
    
  MINLINE command uint16_t C.read_global_var(MateContext *context) {
    return b(context);
  }
    
  MINLINE command mvalue C.read_value(MateContext *context) {
    // values are little-endian
    mvalue v = call V.read((svalue *)&(call GC.base())[context->pc]);

    context->pc += sizeof(svalue);

    return v;
  }
}
