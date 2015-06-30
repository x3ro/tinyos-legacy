/*
 * Copyright (c) 2004-2005 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */
module MOPvarM {
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
  uses {
    interface MotlleTypes as T;
    interface MotlleStack as S;
    interface MotlleGlobals as G;
    interface MotlleVar as LV;
    interface MotlleVar as CV;
    interface MotlleCode as C;
  }
}
implementation {
  command result_t ReadLocal.execute(uint8_t instr, MateContext *context) {
    call S.push(context,
		call LV.read(context, call C.read_local_var(context)));
    return SUCCESS;
  }

  command uint8_t ReadLocal.byteLength() {
    return 1;
  }

  command result_t ReadLocal3.execute(uint8_t instr, MateContext *context) {
    call S.push(context, call LV.read(context, instr - OP_MREADL3));
    return SUCCESS;
  }

  command uint8_t ReadLocal3.byteLength() {
    return 1;
  }

  command result_t ReadClosure.execute(uint8_t instr, MateContext *context) {
    call S.push(context,
		call CV.read(context, call C.read_closure_var(context)));
    return SUCCESS;
  }

  command uint8_t ReadClosure.byteLength() {
    return 1;
  }

  command result_t ReadClosure3.execute(uint8_t instr, MateContext *context) {
    call S.push(context, call CV.read(context, instr - OP_MREADC3));
    return SUCCESS;
  }

  command uint8_t ReadClosure3.byteLength() {
    return 1;
  }

  command result_t ReadGlobal.execute(uint8_t instr, MateContext *context) {
    call S.push(context, call G.read(call C.read_global_var(context)));
    return SUCCESS;
  }

  command uint8_t ReadGlobal.byteLength() {
    return 1;
  }

  command result_t WriteLocal.execute(uint8_t instr, MateContext *context) {
    call LV.write(context, call C.read_local_var(context),
		  call S.get(context, 0));
    return SUCCESS;
  }

  command uint8_t WriteLocal.byteLength() {
    return 1;
  }

  command result_t WriteLocal3.execute(uint8_t instr, MateContext *context) {
    call LV.write(context, instr - OP_MWRITEL3, call S.get(context, 0));
    return SUCCESS;
  }

  command uint8_t WriteLocal3.byteLength() {
    return 1;
  }

  command result_t WriteDiscardLocal.execute(uint8_t instr, MateContext *context) {
    call LV.write(context, call C.read_local_var(context),
		  call S.pop(context, 1));
    return SUCCESS;
  }

  command uint8_t WriteDiscardLocal.byteLength() {
    return 1;
  }

  command result_t WriteDiscardLocal3.execute(uint8_t instr, MateContext *context) {
    call LV.write(context, instr - OP_MWRITEDL3, call S.pop(context, 1));
    return SUCCESS;
  }

  command uint8_t WriteDiscardLocal3.byteLength() {
    return 1;
  }

  command result_t ClearLocal.execute(uint8_t instr, MateContext *context) {
    call LV.write(context, call C.read_local_var(context), call T.nil());
    return SUCCESS;
  }

  command uint8_t ClearLocal.byteLength() {
    return 1;
  }

  command result_t WriteClosure.execute(uint8_t instr, MateContext *context) {
    call CV.write(context, call C.read_closure_var(context),
		  call S.get(context, 0));
    return SUCCESS;
  }

  command uint8_t WriteClosure.byteLength() {
    return 1;
  }

  command result_t WriteDiscardClosure.execute(uint8_t instr, MateContext *context) {
    call CV.write(context, call C.read_closure_var(context),
		  call S.pop(context, 1));
    return SUCCESS;
  }

  command uint8_t WriteDiscardClosure.byteLength() {
    return 1;
  }

  command result_t WriteGlobal.execute(uint8_t instr, MateContext *context) {
    call G.write(call C.read_global_var(context),
		 call S.get(context, 0));
    return SUCCESS;
  }

  command uint8_t WriteGlobal.byteLength() {
    return 1;
  }

  command result_t WriteDiscardGlobal.execute(uint8_t instr, MateContext *context) {
    call G.write(call C.read_global_var(context),
		 call S.pop(context, 1));
    return SUCCESS;
  }

  command uint8_t WriteDiscardGlobal.byteLength() {
    return 1;
  }
}
