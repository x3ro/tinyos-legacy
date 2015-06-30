//$Id: OPhrminnerM.nc,v 1.3 2005/06/22 09:22:34 neturner Exp $

/**
 * Implements the Monibus operation for querying address <code>B</code>.
 * In the case of the sap-flow sensor, B represents the inner velocity
 * measurement.
 *
 * @author Neil E. Turner
 **/

module OPhrminnerM {

  provides {
    interface MateBytecode;
  }

  uses {
    interface Leds;
    interface MateBytecode as MateBytecodePassThru;
    interface MateStacks as Stacks;
  }
}

implementation {
  ////////////// MateBytecode Commands //////////////
  /**
   * Push the op specific arguments onto the Mate stack and pass execution
   * to the generalized monibus op.
   */
  command result_t MateBytecode.execute(uint8_t instruction,
					MateContext* context)
  {
    call Stacks.pushValue(context, 'B');
    //push the number of arguments onto the stack
    call Stacks.pushValue(context, 1);
    call MateBytecodePassThru.execute(instruction, context);
  }

  /**
   *
   */
  command uint8_t MateBytecode.byteLength() {
    return call MateBytecodePassThru.byteLength();
  }
}
