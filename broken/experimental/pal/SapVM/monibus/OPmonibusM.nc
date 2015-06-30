//$Id: OPmonibusM.nc,v 1.14 2005/06/22 09:22:34 neturner Exp $

/**
 * Implements the most basic Monibus operation.
 * <p>
 * In effect, there is no implementation because the the most
 * basic operation is implemented at the lower level.  This operation
 * ends up just being a pass-thru call.
 *
 * @author Neil E. Turner
 */


module OPmonibusM {

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
   * Pass execution thru to the general monibus implementation.
   */
  command result_t MateBytecode.execute(uint8_t instruction,
					MateContext* context)
  {
    //push the number of arguments onto the stack
    //in this case the arguments come from the scripting layer
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
