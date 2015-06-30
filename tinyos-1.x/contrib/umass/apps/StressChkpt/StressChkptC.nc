/*
 * Test Compaction
 */
includes common_header;
includes sizes;

configuration StressChkptC {
}

implementation {
    components Main,
      StressChkptM,
      ChunkStorageM,
      FalC,
      ConsoleC,
      LedsC,
      StackM,
      Crc8M,
      StreamM,
      CheckpointM,
      RootDirectoryC;

    Main.StdControl -> StressChkptM;
    Main.StdControl -> FalC;
    Main.StdControl -> ChunkStorageM;
    Main.StdControl -> RootDirectoryC;

    /* Wire the chunk storage system */
    //FlashM -> PageEEPROMC.PageEEPROM[unique("FAL")];
    ChunkStorageM.GenericFlash -> FalC.GenericFlash[unique("Flash")]; 
    ChunkStorageM.Leds -> LedsC;
    ChunkStorageM.Crc8 -> Crc8M;

    /* Wire the data structures */
    StreamM.ChunkStorage -> ChunkStorageM.ChunkStorage[unique("Fal")];
    StreamM.Stack -> StackM.Stack[1];
    StackM.ChunkStorage -> ChunkStorageM.ChunkStorage[unique("Fal")];

    /* Debugging */
    StackM.Leds -> LedsC;
    StreamM.Leds -> LedsC;
    CheckpointM.Leds -> LedsC;
    
    StressChkptM.Console -> ConsoleC;
    StreamM.Console -> ConsoleC;
    StackM.Console -> ConsoleC;
    ChunkStorageM.Console -> ConsoleC;
    RootDirectoryC.Console -> ConsoleC;
    CheckpointM.Console -> ConsoleC;
    FalC.Console -> ConsoleC;
    
    /* Checkpointing */
    CheckpointM.ChunkStorage -> ChunkStorageM.ChunkStorage[unique("Fal")];
    CheckpointM.Stack -> StackM.Stack[unique("Stack")];
    CheckpointM.RootPtrAccess -> StackM.RootPtrAccess[0];
    CheckpointM.RootDirectory -> RootDirectoryC;

    CheckpointM.Serialize -> ChunkStorageM.Serialize;
    CheckpointM.Serialize -> StreamM.Serialize[0];

    /* Compaction */
    ChunkStorageM.Compaction -> StreamM.Compaction[0];

    RootDirectoryC.GenericFlash -> FalC.GenericFlash[unique("Flash")];

    /* Application */
    StressChkptM.ChunkStorage -> ChunkStorageM.ChunkStorage[unique("Fal")];
    StressChkptM.Leds -> LedsC;
    StressChkptM.GenericFlash -> FalC.GenericFlash[unique("Flash")];
    StressChkptM.Stream -> StreamM.Stream[unique("Stream")];
    StressChkptM.Checkpoint -> CheckpointM.Checkpoint;
    StressChkptM.RootDirectory -> RootDirectoryC;
}
