// $Id: TOSBase.nc,v 1.1.1.1 2006/05/04 23:08:21 ucsbsensornet Exp $


/**
 * @author Phil Buonadonna
 * @author Gilman Tolle
 */

configuration TOSBase {
}
implementation {
  components Main, TOSBaseM, RadioCRCPacket as Comm, FramerM;
  components UART, LedsC, TimerC;

  Main.StdControl -> TOSBaseM;

  TOSBaseM.UARTControl -> FramerM;
  TOSBaseM.UARTSend -> FramerM;
  TOSBaseM.UARTReceive -> FramerM;
  TOSBaseM.UARTTokenReceive -> FramerM;

  TOSBaseM.RadioControl -> Comm;
  TOSBaseM.RadioSend -> Comm;
  TOSBaseM.RadioReceive -> Comm;

  TOSBaseM.Leds -> LedsC;

  FramerM.ByteControl -> UART;
  FramerM.ByteComm -> UART;

  TOSBaseM.Timer -> TimerC.Timer[unique("Timer")];
}
