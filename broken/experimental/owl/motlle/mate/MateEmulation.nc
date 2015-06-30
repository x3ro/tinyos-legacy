module MateEmulation
{
  provides {
    interface MateStacks;
  }
  uses {
    interface MotlleStack as S;
    interface MotlleTypes as T;
    interface MotlleValues as V;
    interface MateError as E;
  }
}
implementation {
  command result_t MateStacks.resetStacks(MateContext* context) {
    return SUCCESS;
  }

  command result_t MateStacks.pushValue(MateContext* context, int16_t val) {
    call S.push(context, call T.make_int(val));
    return SUCCESS;
  }

  command result_t MateStacks.pushReading(MateContext* context, uint8_t type, int16_t val) {
    call S.push(context, call T.make_int(val));
    return SUCCESS;
  }

  command result_t MateStacks.pushBuffer(MateContext* context, MateDataBuffer* buf) {
    call E.error(context, MOTLLE_ERROR_BAD_VALUE);
    return SUCCESS;
  }

  
  command result_t MateStacks.pushOperand(MateContext* context, MateStackVariable* var) {
    switch (var->type)
      {
      case MATE_TYPE_INTEGER:
	return call MateStacks.pushValue(context, var->value.var);
      case MATE_TYPE_BUFFER:
	return call MateStacks.pushBuffer(context, var->buffer.var);
      default:
	return call MateStacks.pushReading(context, var->type, var->value.var);
      case MATE_TYPE_NONE: case MATE_TYPE_END:
	call E.error(context, MOTLLE_ERROR_BAD_VALUE);
	break;
      }
    return SUCCESS;
  }
  
  command MateStackVariable* MateStacks.popOperand(MateContext* context) {
    static MateStackVariable var; // ugly hack
    mvalue v = call S.pop(context, 1);
    ivalue x = call V.integerp(v) ? call V.integer(v) : 0;

    var.type = MATE_TYPE_INTEGER;
    var.value.var = x;
    
    return &var;
  }

  command uint8_t MateStacks.getOpStackDepth(MateContext* context) {
    return 1; // ugly hack
  }
}
