/*
 * Copyright (c) 2004-2005 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */
module MOPclosureM {
  provides {
    interface MateBytecode;
  }
  uses {
    interface MotlleCode as C;
    interface MotlleVar as RawLV;
    interface MotlleVar as RawCV;
    interface MotlleStack as S;
    interface MotlleValues as V;
    interface MotlleTypes as T;
  }
}
implementation {
  command result_t MateBytecode.execute(uint8_t instr, MateContext *context) {
    uint8_t nvars = call C.read_uint8_t(context), var;
    vclosure c = call V.allocate(itype_closure, (nvars + 1) * sizeof(svalue));

    if (!c)
      return SUCCESS;

    for (var = 0; var < nvars; var++)
      {
	uint8_t varspec = call C.read_uint8_t(context);
	uint8_t whichvar = varspec >> 1;
	mvalue v;

	if (!(varspec & 1))
	  v = call RawLV.read(context, whichvar);
	else
	  v = call RawCV.read(context, whichvar);

	call V.write(&c->variables[var], v);
      }
    call V.write(&c->code, call C.read_value(context));
    call S.push(context, call T.make_closure(c));

    return SUCCESS;
  }

  command uint8_t MateBytecode.byteLength() {
    return 1;
  }
}
