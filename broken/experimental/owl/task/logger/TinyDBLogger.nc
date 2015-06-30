// Intercept TinyDB messages and log them
includes TinyDBLogger;
configuration TinyDBLogger {
  provides interface StdControl;
}
implementation {
  components PersistentLogger, TinyDBLoggerM, ByteEEPROM, Command,
    GENERICCOMMPROMISCUOUS as Comm, LedsC, TupleRouterM, LogicalTime,
    QueuedSend, WDTC;
  
  StdControl = TinyDBLoggerM;
  StdControl = ByteEEPROM;

  TupleRouterM.queryResultHook -> TinyDBLoggerM;

  TinyDBLoggerM -> PersistentLogger.AllocationReq[TINYDB_EEPROM_ID];
  TinyDBLoggerM -> PersistentLogger.LogData[TINYDB_EEPROM_ID];
  TinyDBLoggerM -> ByteEEPROM.ReadData[TINYDB_EEPROM_ID];
  TinyDBLoggerM.ReceiveMsg -> Comm.ReceiveMsg[AM_LREADREQUESTMSG];
  TinyDBLoggerM.SendMsg -> QueuedSend.SendMsg[AM_LREADDATAMSG];
  TinyDBLoggerM.Leds -> LedsC;
  TinyDBLoggerM.Time -> LogicalTime;
  TinyDBLoggerM.WDT -> WDTC;

  TinyDBLoggerM.ClearCmd -> Command.Cmd[unique("Command")];
  TinyDBLoggerM.OffsetCmd -> Command.Cmd[unique("Command")];
}
