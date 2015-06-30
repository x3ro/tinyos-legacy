/*
 * Copyright (c) 2004-2005 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */
module MotlleDecoderM {
  provides interface MotlleCode as C;
  uses {
    interface MotlleValues as V;
    interface MotlleGC as GC;
  }
}
implementation {
  MINLINE uint8_t b(MateContext *context) {
    return (call GC.base())[context->pc++];
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
    mvalue v = call V.read_unaligned((svalue *)&(call GC.base())[context->pc]);

    context->pc += sizeof(svalue);

    return v;
  }
}
