configuration DebugC{
    provides interface StdControl;
}

implementation {
    components DebugM, DebugUARTBufferC;   
    StdControl = DebugM;
    DebugM.SendVarLenPacket -> DebugUARTBufferC;
    DebugM.SendVarLenPacketControl -> DebugUARTBufferC;
}
