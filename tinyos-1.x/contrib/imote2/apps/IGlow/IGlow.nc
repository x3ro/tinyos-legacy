//@author Ralph Kling

configuration IGlow {
}

implementation {
    components Main,
        IGlowM,
        TimerC,
        UTimerC,
        BluSHC,
        LedsC;

    Main.StdControl -> BluSHC.StdControl;
    Main.StdControl -> TimerC.StdControl;
    Main.StdControl -> UTimerC.StdControl;
    Main.StdControl -> IGlowM.StdControl;

    IGlowM.Timer -> TimerC.Timer[unique("Timer")];
    IGlowM.UTimer -> UTimerC.UTimer[unique("Timer")];
    IGlowM.Leds -> LedsC;
}
