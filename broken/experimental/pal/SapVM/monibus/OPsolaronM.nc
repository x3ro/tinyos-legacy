
includes Mate;

module OPsolaronM {
  provides interface MateBytecode;
  uses {
    interface MateStacks as Stacks;
    interface MateTypes as Types;
  }
}

implementation {

  command result_t MateBytecode.execute(uint8_t instr,
					    MateContext* context) {
    //TOSH_MAKE_GIO0_OUTPUT();
    //TOSH_SET_GIO0_PIN();
    TOSH_MAKE_ADC3_OUTPUT();
    TOSH_SET_ADC3_PIN();

    return SUCCESS;
  }

  command uint8_t MateBytecode.byteLength() {return 1;}

}
