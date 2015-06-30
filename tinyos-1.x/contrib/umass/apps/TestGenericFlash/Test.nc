/*
 * file:        Format.nc
 * description:
 *
 */
 
configuration Test {
}

implementation {
    components Main, TestC, FalC, LedsC, ConsoleC, TimerC;

    Main.StdControl -> TestC;
    Main.StdControl -> FalC;
    Main.StdControl -> TimerC;

    TestC.Console -> ConsoleC;
    TestC.GenericFlash -> FalC.GenericFlash[unique("Fal")];
    TestC.Leds -> LedsC;
    TestC.Timer -> TimerC.Timer[unique("Timer")];
}
