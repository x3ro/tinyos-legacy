includes MyMoteInfoMsg;
includes MyPCCmdMsg;
includes IntMsg;

/**
 * This configuration wires different modules so that the mote
 * waits for a command (from UART) to indicate whom to send how many packets
 * over the UART. It also implements the code for receiver which can receive
 * packets from RF interface and collect the stats on the received packets.
 * The Red LED is toggled whenever a new packet is sent or received. 
 */

configuration SendReceivePkt { }
implementation
{
  components Main, SendReceivePktM
             , TimerC
             , LedsC
             , GenericComm as Comm;

  Main.StdControl -> SendReceivePktM;
  Main.StdControl -> TimerC;
  
  SendReceivePktM.SendPktTimer -> TimerC.Timer[unique("Timer")];
  SendReceivePktM.SendInfoTimer -> TimerC.Timer[unique("Timer")];
  SendReceivePktM.Leds -> LedsC;
  SendReceivePktM.CommControl -> Comm;
  SendReceivePktM.ReceiveRF -> Comm.ReceiveMsg[AM_INTMSG];
  SendReceivePktM.ReceiveUARTCmd -> Comm.ReceiveMsg[AM_MYPCCMDMSG];
  SendReceivePktM.SendRF -> Comm.SendMsg[AM_INTMSG];
  SendReceivePktM.SendUARTCmd -> Comm.SendMsg[AM_MYPCCMDMSG];
  //SendReceivePktM.ReceiveUART -> Comm.ReceiveMsg[AM_MYMOTEINFOMSG];
  SendReceivePktM.SendUARTInfo -> Comm.SendMsg[AM_MYMOTEINFOMSG];
}

