configuration PersistentLogger
{
  provides {
    interface AllocationReq[uint8_t clientId];
    interface LogData[uint8_t clientId];
  }
}
implementation 
{
  components PersistentLoggerM, ByteEEPROMC, PageEEPROMC, ByteEEPROMAllocate;

  LogData = ByteEEPROMC.PersistentLog;
  AllocationReq = PersistentLoggerM;

  PersistentLoggerM.IPersistent <- ByteEEPROMC;
  PersistentLoggerM.PageEEPROM -> PageEEPROMC.PageEEPROM[unique("PageEEPROM")];
  PersistentLoggerM.Alloc -> ByteEEPROMAllocate;
  PersistentLoggerM.getRegion -> ByteEEPROMAllocate;
}
