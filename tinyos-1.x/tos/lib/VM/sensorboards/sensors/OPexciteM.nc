/**
 * @author David Gay
 */


includes Mate;

module OPexciteM {
  provides interface MateBytecode;
  uses {
    interface Power[uint8_t excitation];
    interface MateStacks;
    interface MateTypes;
    interface MateError as Error;
  }
}

implementation {
  command result_t MateBytecode.execute(uint8_t instr, MateContext *context) {
    uint16_t vvoltage;

    MateStackVariable *onoff = call MateStacks.popOperand(context);
    MateStackVariable *voltage = call MateStacks.popOperand(context);
    if (!(call MateTypes.checkTypes(context, onoff, MATE_TYPE_INTEGER) &&
	  call MateTypes.checkTypes(context, voltage, MATE_TYPE_INTEGER)))
      return FAIL;

    vvoltage = voltage->value.var;
    if (!(onoff->value.var ?
	  call Power.on[vvoltage]() : call Power.off[vvoltage]()))
      call Error.error(context, MATE_ERROR_ARITHMETIC);      
    return SUCCESS;
  }

  command uint8_t MateBytecode.byteLength() {return 1;}

  default command result_t Power.on[uint8_t excitation]() {
    return FAIL;
  }

  default command result_t Power.off[uint8_t excitation]() {
    return FAIL;
  }
}
