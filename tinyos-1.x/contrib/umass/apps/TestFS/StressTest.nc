/*
 * Test Compaction
 */
includes common_header;
includes sizes;

configuration StressTest {
}

implementation {
    components Main,
      StressTestM,
      ChunkStorageM,
      FlashM,
      FalC,
      ConsoleC,
      LedsC,
      StackM,
      Crc8M,
      CheckpointM,
      CompactionAbsorbM,
      RootDirectoryC,
      FileSystemM,
      FileM,
      IndexM,
      ArrayM,
      TimerC,
      RootPtrAccessAbsorbM;

    Main.StdControl -> StressTestM;
    Main.StdControl -> FalC;
    Main.StdControl -> ChunkStorageM;
    Main.StdControl -> RootDirectoryC;
    Main.StdControl -> FileSystemM;
    Main.StdControl -> IndexM;
    Main.StdControl -> TimerC;

    /* Wire the chunk storage system */
    ChunkStorageM.GenericFlash -> FalC.GenericFlash[unique("Flash")];
    RootDirectoryC.GenericFlash -> FalC.GenericFlash[unique("Flash")]; 
    ChunkStorageM.Leds -> LedsC;
    ChunkStorageM.Crc8 -> Crc8M;

    /* Wire the FS */
    StackM.ChunkStorage -> ChunkStorageM.ChunkStorage[unique("Fal")];
    FileSystemM.ChunkStorage -> ChunkStorageM.ChunkStorage[unique("Fal")];
    FileM.FileSystem -> FileSystemM;
    ArrayM.ChunkStorage -> ChunkStorageM.ChunkStorage[unique("Fal")];
    IndexM.ChunkStorage -> ChunkStorageM.ChunkStorage[unique("Fal")];
    FileM.Index -> IndexM.Index[unique("Index")];

    FileM.IndexRootPtrAccess -> IndexM.RootPtrAccess[0];
    FileSystemM.Checkpoint -> CheckpointM;

    /* Debugging */
    StackM.Leds -> LedsC;
    ArrayM.Leds -> LedsC;
    IndexM.Leds -> LedsC;
    CheckpointM.Leds -> LedsC;
    FileSystemM.Leds -> LedsC;
    FileM.Leds -> LedsC;

    //FalC.Console -> ConsoleC;    
    StressTestM.Console -> ConsoleC;
    //FileSystemM.Console -> ConsoleC;
    IndexM.Console -> ConsoleC;
    //FileM.Console -> ConsoleC;
    //FlashM.Console -> ConsoleC;
    StackM.Console -> ConsoleC;
    //ChunkStorageM.Console -> ConsoleC;
    RootDirectoryC.Console -> ConsoleC;
    CheckpointM.Console -> ConsoleC;
    
    /* Checkpointing */
    CheckpointM.ChunkStorage -> ChunkStorageM.ChunkStorage[unique("Fal")];
    CheckpointM.Stack -> StackM.Stack[unique("Stack")];
    CheckpointM.RootPtrAccess -> StackM.RootPtrAccess[0];
    CheckpointM.RootDirectory -> RootDirectoryC;

    CheckpointM.Serialize -> ChunkStorageM.Serialize;
    CheckpointM.Serialize -> FileSystemM.Serialize;

    IndexM.Array -> ArrayM.Array;

    /* Compaction */
    ChunkStorageM.Compaction -> IndexM.Compaction[0];

    /* Application */
    StressTestM.GenericFlash -> FalC.GenericFlash[unique("Flash")]; 
    StressTestM.Leds -> LedsC;
    StressTestM.File -> FileM;
    StressTestM.Timer -> TimerC.Timer[unique("Timer")];
}
