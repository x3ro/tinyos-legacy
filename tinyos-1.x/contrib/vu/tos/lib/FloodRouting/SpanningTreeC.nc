configuration SpanningTreeC {
    provides {
        interface FloodingPolicy;
        interface SpanningTreeParameters;
    }
}

implementation {
    components RemoteControlC, SpanningTreeFormationC, SpanningTreePolicyM, SpanningTreeCommandsM, LedsC;
    
    FloodingPolicy = SpanningTreePolicyM;
    //SpanningTreePolicyM.Leds -> LedsC;
    SpanningTreePolicyM.SpanningTreeParameters -> SpanningTreeFormationC;
    SpanningTreeParameters = SpanningTreeFormationC;
    SpanningTreeCommandsM.SpanningTreeParameters -> SpanningTreeFormationC;
	RemoteControlC.DataCommand[0xa0] -> SpanningTreeCommandsM.SpanningTreeDownloadConfigurationCommands;
    RemoteControlC.IntCommand[0xa0] -> SpanningTreeCommandsM.IntCommand;
}
