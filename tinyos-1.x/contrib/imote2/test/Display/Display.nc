
configuration Display {
}
implementation {
    components Main,
        DisplayM,
        TimerC,
        BluSHC,
        SSP2C,
        LedsC;
    
    Main.StdControl -> BluSHC.StdControl;
    Main.StdControl -> TimerC.StdControl;
    Main.StdControl -> DisplayM.StdControl;

    DisplayM.Timer -> TimerC.Timer[unique("Timer")];

    DisplayM.Leds -> LedsC;
 
    DisplayM.SSP -> SSP2C;
    DisplayM.RawData -> SSP2C;
}
