//$Id: OPhrmouterM.nc,v 1.3 2005/06/22 09:22:34 neturner Exp $

/**
 * Implements the Monibus operation for querying address <code>A</code>.
 * In the case of the sap-flow sensor, A represents the inner velocity
 * measurement.
 *
 * @author Neil E. Turner
 **/

module OPhrmouterM {

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
    call Stacks.pushValue(context, 'A');
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
