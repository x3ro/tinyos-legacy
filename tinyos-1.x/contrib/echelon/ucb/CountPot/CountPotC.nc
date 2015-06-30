// $Id: CountPotC.nc,v 1.1 2004/04/25 23:59:07 cssharp Exp $
// @author Cory Sharp <cssharp@eecs.berkeley.edu>

// CountSend:
//   Count to the leds and send it over the radio.

configuration CountPotC
{
}
implementation
{
  components Main
           , CountPotM
	   , TimerC
	   , I2CPotC
	   , LedsC
	   ;
  
  Main.StdControl -> CountPotM;
  Main.StdControl -> I2CPotC;
  Main.StdControl -> TimerC;

  CountPotM.Timer -> TimerC.Timer[unique("Timer")];
  CountPotM.I2CPot -> I2CPotC;
  CountPotM.Leds -> LedsC;
}

