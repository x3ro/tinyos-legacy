/**
 * Try out the interrupt attached to the user button on the telos b
 *
 * Code provided by Joe Palstre (from an e-mail message)
 *
 * Andrew Christian <andrew.christian@hp.com>
 * March 2005
 */

configuration UserButton {
}
implementation {
  components Main, MSP430InterruptC, UserButtonM, LedsC;

  Main.StdControl -> UserButtonM;
  
  UserButtonM.UserInt -> MSP430InterruptC.Port27;
  UserButtonM.Leds    -> LedsC;
}

