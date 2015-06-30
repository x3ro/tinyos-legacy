/**
 * Configuration for GlowLight
 *
 * Copyright (C) 2005 Shockfish SA
 *
 * Authors:             Maxime Muller
 *
 **/

configuration GlowLightC { }

implementation
{
    components Main,
	GlowLightM,
	LedsIntensityC,
	TimerC,
	LightC,
	RandomLFSR,
	OscopeC,
	GenericComm;

    Main.StdControl -> GlowLightM;
    Main.StdControl -> LedsIntensityC;
    Main.StdControl -> TimerC;
    Main.StdControl -> LightC;
    Main.StdControl -> OscopeC;
    Main.StdControl -> GenericComm;

    GlowLightM.LedsI -> LedsIntensityC;
    GlowLightM.LightADC -> LightC;
    GlowLightM.Random -> RandomLFSR;
    GlowLightM.Timer -> TimerC.Timer[unique("Timer")];
    GlowLightM.Blink -> TimerC.Timer[unique("Blink")];
    GlowLightM.Node0 -> OscopeC.Oscope[0];
    GlowLightM.Node1 -> OscopeC.Oscope[1];
    GlowLightM.Node2 -> OscopeC.Oscope[2];
    GlowLightM.SendMsg -> GenericComm.SendMsg[5];
    GlowLightM.ReceiveMsg -> GenericComm.ReceiveMsg[5];
}
