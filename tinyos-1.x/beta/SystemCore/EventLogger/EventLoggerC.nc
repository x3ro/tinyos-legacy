includes SNMS;
includes PageEEPROM;
includes ByteEEPROMInternal;
includes EventLogger;

configuration EventLoggerC {
  provides {
    interface StdControl;
    interface EventLogger;
  }
} 

implementation {
  components 
    EventLoggerM, 
    MgmtAttrsC,
    RSSIMultiHopRouter as Multihop,
    DripC,
    AMNamingM,
    SharedMsgBufM,
    ByteEEPROM,
    RandomLFSR,
    SimpleTime,
    TimerC,
    LedsC;
  
  StdControl = EventLoggerM;
  StdControl = ByteEEPROM;
  StdControl = TimerC;
  StdControl = Multihop;
  StdControl = DripC;
  StdControl = MgmtAttrsC;
  StdControl = SimpleTime;

  EventLogger = EventLoggerM;

  EventLoggerM.Leds -> LedsC;

  EventLoggerM.Send -> Multihop.Send[AM_LOGENTRYMSG];

  EventLoggerM.CmdReceive -> DripC.Receive[AM_EVENTLOGGERCMDMSG];
  EventLoggerM.CmdDrip -> DripC.Drip[AM_EVENTLOGGERCMDMSG];
  EventLoggerM.Naming -> AMNamingM;

  EventLoggerM.AllocationReq -> ByteEEPROM.AllocationReq[EVENTLOGGER_EEPROM_ID];
  EventLoggerM.LogData  -> ByteEEPROM.LogData[EVENTLOGGER_EEPROM_ID];
  EventLoggerM.ReadData -> ByteEEPROM.ReadData[EVENTLOGGER_EEPROM_ID];

  EventLoggerM.Time -> SimpleTime.Time;

  EventLoggerM.Timer -> TimerC.Timer[unique("Timer")];
  EventLoggerM.Random -> RandomLFSR;

  EventLoggerM.SharedMsgBuf -> SharedMsgBufM.SharedMsgBuf[BUF_SNMS];

  EventLoggerM.MA_LogReadOffset -> MgmtAttrsC.MgmtAttr[unique("MgmtAttr")];
  EventLoggerM.MA_LogWriteOffset -> MgmtAttrsC.MgmtAttr[unique("MgmtAttr")];
}
