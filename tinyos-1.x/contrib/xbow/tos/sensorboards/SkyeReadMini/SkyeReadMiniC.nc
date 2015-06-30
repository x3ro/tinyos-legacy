/*
 *
 * Systemic Realtime Design, LLC.
 * http://www.sysrtime.com
 *
 * Authors:  Qingwei Ma
 *           Michael Li
 *
 * Date last modified:  9/30/04
 *
 */
includes SkyeReadMini;
includes RFIDtags;

configuration SkyeReadMiniC 
{
  provides
  {
    interface StdControl;
    interface SkyeReadMini;
  }
}

implementation 
{
  components SkyeReadMiniM, RFIDUARTPacket as Packet, TimerC, SGDriver; 

  StdControl = SkyeReadMiniM;
  SkyeReadMini = SkyeReadMiniM;

  SkyeReadMiniM.UARTControl -> Packet;
  SkyeReadMiniM.MiniSleep -> TimerC.Timer[unique("Timer")];
  SkyeReadMiniM.WakeUpDelay -> TimerC.Timer[unique("Timer")];
  SkyeReadMiniM.ResponseTimeout -> TimerC.Timer[unique("Timer")];
  SkyeReadMiniM.SendUART -> Packet.SendVar;
  SkyeReadMiniM.ReceiveUART -> Packet.Receive;

  SkyeReadMiniM.SGData -> SGDriver;
  SkyeReadMiniM.SGControl -> SGDriver;
}
