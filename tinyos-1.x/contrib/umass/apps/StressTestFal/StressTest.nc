/*
 * Test Compaction
 */
includes common_header;
includes sizes;

configuration StressTest {
}

implementation {
    components Main, StressTestC, ChunkStorageM, ConsoleC,
               LedsC, FalC;

    Main.StdControl -> FalC;
    Main.StdControl -> ChunkStorageM;
    Main.StdControl -> StressTestC;

    /* Wire the chunk storage system */
    ChunkStorageM.GenericFlash -> FalC.GenericFlash[unique("Flash")];
    ChunkStorageM.Leds -> LedsC;
    
    StressTestC.Console -> ConsoleC;
    ChunkStorageM.Console -> ConsoleC;
    FalC.Console -> ConsoleC;
    
    /* Application */
    StressTestC.ChunkStorage -> ChunkStorageM.ChunkStorage[unique("Fal")];
    StressTestC.Leds -> LedsC;
    StressTestC.GenericFlash -> FalC.GenericFlash[unique("Flash")];
}
