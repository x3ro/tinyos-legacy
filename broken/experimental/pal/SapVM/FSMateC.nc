includes Mate;
includes FSMate;

// wire things to me
configuration FSMateC {
  provides interface MateBytecode as FWrite;
  provides interface MateBytecode as FFormat;
  provides interface MateBytecode as FRead;
}

implementation {
  components FSMateM, MStacksProxy, MTypesProxy, MQueueProxy;
  components MBufferProxy, MContextSynchProxy, MateEngine as VM;
  components DataCacheM, InternalFlashC, Main;
  components FlashLoggerC;
  components LedsC;

  FSMateM.Queue -> MQueueProxy;
  FSMateM.Stacks -> MStacksProxy;
  FSMateM.Buffer -> MBufferProxy;
  FSMateM.Synch -> MContextSynchProxy;
  FSMateM.TypeCheck -> MTypesProxy;
  
  FSMateM.VolumeInit -> FlashLoggerC;
  FSMateM.LogRead -> FlashLoggerC;
  FSMateM.LogWrite -> FlashLoggerC;
  
  FSMateM.EngineStatus -> VM;
  FWrite = FSMateM.FWrite;
  FRead = FSMateM.FRead;
  FFormat = FSMateM.FFormat;
  FSMateM.DataCacheReset -> DataCacheM.reset;
  FSMateM.flashError -> DataCacheM.flashError;
  FSMateM.DataCacheControl -> DataCacheM.StdControl;
  FSMateM.getRecordSize <- DataCacheM.getRecordSize;
  FSMateM.IFlash -> InternalFlashC;
  Main.StdControl -> FSMateM;

  FSMateM.Leds -> LedsC;
  DataCacheM.Leds -> LedsC;
}
