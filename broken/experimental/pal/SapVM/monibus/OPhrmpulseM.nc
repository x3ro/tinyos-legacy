//$Id: OPhrmpulseM.nc,v 1.5 2005/08/18 00:47:52 neturner Exp $

/**
 * Implements the sap-flow specific, Monibus operation for firing a heat pulse.
 *
 * @author Neil E. Turner
 **/

module OPhrmpulseM {

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
    call Stacks.pushValue(context, 'p');
    call Stacks.pushValue(context, 's');
    call Stacks.pushValue(context, '}');
    //push the number of arguments onto the stack
    call Stacks.pushValue(context, 3);
    call MateBytecodePassThru.execute(instruction, context);
  }

  /**
   *
   */
  command uint8_t MateBytecode.byteLength() {
    return call MateBytecodePassThru.byteLength();
  }
}
