/*
 * Test Compaction
 */
includes common_header;
includes sizes;

configuration StressTestC {
}

implementation {
    components Main, StressTestM, ChunkStorageM, FalC, ConsoleC, Crc8M,
               LedsC, StackM, StreamM, CheckpointM,
               IndexM, ArrayM, StreamIndexM, QueueM, CompactionAbsorbM;

    Main.StdControl -> StressTestM;
    Main.StdControl -> FalC;
    Main.StdControl -> ChunkStorageM;
    Main.StdControl -> IndexM;

    /* Wire the chunk storage system */
    ChunkStorageM.GenericFlash -> FalC.GenericFlash[unique("Flash")]; 
    ChunkStorageM.Leds -> LedsC;
    ChunkStorageM.Compaction -> CompactionAbsorbM;
    ChunkStorageM.Crc8 -> Crc8M;

    /* Wire the data structures */
    StackM.ChunkStorage -> ChunkStorageM.ChunkStorage[unique("Fal")];
    StreamM.ChunkStorage -> ChunkStorageM.ChunkStorage[unique("Fal")];
    QueueM.ChunkStorage -> ChunkStorageM.ChunkStorage[unique("Fal")];
    ArrayM.ChunkStorage -> ChunkStorageM.ChunkStorage[unique("Fal")];
    IndexM.ChunkStorage -> ChunkStorageM.ChunkStorage[unique("Fal")];
    StreamIndexM.ChunkStorage -> ChunkStorageM.ChunkStorage[unique("Fal")];
    StreamIndexM.Stream -> StreamM.Stream[unique("Stream")];
    StreamIndexM.Index -> IndexM.Index[unique("Index")];
    IndexM.Array -> ArrayM.Array;
    StreamM.Stack -> StackM.Stack[unique("Stack")];
    StackM.Console -> ConsoleC;
    ChunkStorageM.Console -> ConsoleC;

    StackM.Leds -> LedsC;
    StreamM.Leds -> LedsC;
    ArrayM.Leds -> LedsC;
    IndexM.Leds -> LedsC;
    StreamIndexM.Leds -> LedsC;
    
    /* Debugging */
    StressTestM.Console -> ConsoleC;
    QueueM.Console -> ConsoleC;
    StreamM.Console -> ConsoleC;
    StackM.Console -> ConsoleC;
    IndexM.Console -> ConsoleC;
    ArrayM.Console -> ConsoleC;
    StreamIndexM.Console -> ConsoleC;
    
    /* Testing */
    StressTestM.ChunkStorage -> ChunkStorageM.ChunkStorage[unique("Fal")];
    StressTestM.Leds -> LedsC;
    StressTestM.Stack -> StackM.Stack[unique("Stack")];
    StressTestM.GenericFlash -> FalC.GenericFlash[unique("Flash")];
    StressTestM.Queue -> QueueM.Queue[unique("Queue")];
    StressTestM.StreamIndex -> StreamIndexM.StreamIndex[unique("StreamIndex")];
    StressTestM.Index -> IndexM.Index[unique("Index")];
    StressTestM.Stream -> StreamM.Stream[unique("Stream")];
}
