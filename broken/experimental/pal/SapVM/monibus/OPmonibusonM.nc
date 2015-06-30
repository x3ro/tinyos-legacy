
includes Mate;

module OPmonibusonM {
  provides interface MateBytecode;
  uses {
    interface MateStacks as Stacks;
    interface MateTypes as Types;
  }
}

implementation {

  command result_t MateBytecode.execute(uint8_t instr,
					    MateContext* context) {
    //TOSH_MAKE_GIO1_OUTPUT();
    //TOSH_SET_GIO1_PIN();
    TOSH_MAKE_ADC2_OUTPUT();
    TOSH_SET_ADC2_PIN();    
    
    return SUCCESS;
  }

  command uint8_t MateBytecode.byteLength() {return 1;}

}
