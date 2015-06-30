includes Storage;

configuration FlashLoggerC {
  provides {
    interface LogRead;
    interface LogWrite;
    interface VolumeInit;
  }
}

implementation {
  components FlashLoggerM, InternalFlashC, BlockStorageC;
  components FormatStorageC;
  components LedsC;

  components CC2420RadioC as RadioControl;
  FlashLoggerM.RadioControl -> RadioControl;

  LogRead = FlashLoggerM;
  LogWrite = FlashLoggerM;
  VolumeInit = FlashLoggerM;
  FlashLoggerM.IFlash -> InternalFlashC;
  FlashLoggerM.Leds -> LedsC;
  // 0, 1, 15 for deluge
  /*
  FlashLoggerM.BlockWrite -> BlockStorageC.BlockWrite[unique("BlockWrite")];
  FlashLoggerM.BlockRead -> BlockStorageC.BlockRead[unique("BlockRead")];
  FlashLoggerM.Mount -> BlockStorageC.Mount[unique("Mount")];
  */
  FlashLoggerM.BlockWrite -> BlockStorageC.BlockWrite[FSMATE_VOL_ID];
  FlashLoggerM.BlockRead -> BlockStorageC.BlockRead[FSMATE_VOL_ID];
  FlashLoggerM.Mount -> BlockStorageC.Mount[FSMATE_VOL_ID];

  FlashLoggerM.FormatStorage -> FormatStorageC;

}
