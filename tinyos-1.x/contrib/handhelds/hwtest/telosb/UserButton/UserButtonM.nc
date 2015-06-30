/**
 * Try out the interrupt attached to the user button on the telos b
 *
 * Code provided by Joe Palstre (from an e-mail message)
 *
 * Andrew Christian <andrew.christian@hp.com>
 * March 2005
 */

module UserButtonM {
  provides {
    interface StdControl;
  }
  uses {
    interface MSP430Interrupt as UserInt;
    interface Leds;
  }
}
implementation {
  uint8_t g_leds;

  command result_t StdControl.init() 
  {
    atomic g_leds = 0;
    call Leds.init();
    return SUCCESS;
  }

  command result_t StdControl.start()
  {
    atomic {
      call UserInt.disable();
      call UserInt.clear();
      call UserInt.edge(FALSE);
      call UserInt.enable();
    }

    return SUCCESS;
  }

  command result_t StdControl.stop()
  {
    atomic {
      call UserInt.disable();
      call UserInt.clear();
    }
    return SUCCESS;
  }

  async event void UserInt.fired() 
  {
    g_leds++;
    call Leds.set( g_leds & 0x07 );
    call UserInt.clear();
  }
}


