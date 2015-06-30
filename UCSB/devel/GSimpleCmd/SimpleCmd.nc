// $Id: SimpleCmd.nc,v 1.1.1.1 2006/05/04 23:08:19 ucsbsensornet Exp $

/** 
 * SimpleCmd is a TinyOS configuration module. 
 * It defines the wiring used by SimpleCmdM module.
 * It is wired to Main module's StdControl interface.
 * It components GenericComm's CommControl and ReceiveMsg interfaces
 * to receive AM_SIMPLECMDMSG from base station. It excecutes 
 * a command using either Pot or Leds interface depending as to 
 * the command type. 
 */

includes SimpleCmdMsg;

configuration SimpleCmd {
  provides interface ProcessCmd;
}
implementation {
  components Main, SimpleCmdM, GenericComm as Comm, PotC;
  components LedsC, Logger, SysTimeStampingC as TimeStampingC;

  Main.StdControl -> SimpleCmdM;
  SimpleCmdM.Leds -> LedsC;

  ProcessCmd = SimpleCmdM.ProcessCmd;
  SimpleCmdM.CommControl -> Comm;

  SimpleCmdM.ReceiveCmdMsg -> Comm.ReceiveMsg[AM_SIMPLECMDMSG];
  SimpleCmdM.SendLogMsg -> Comm.SendMsg[AM_LOGMSG];

  SimpleCmdM.LoggerWrite -> Logger.LoggerWrite;
  SimpleCmdM.LoggerRead -> Logger;

  SimpleCmdM.Pot -> PotC;
  SimpleCmdM.TimeStamping -> TimeStampingC;
}
