
configuration ConsoleC {
    provides interface Console;
}

implementation {
    components ConsoleM, HPLUARTC;
    Console = ConsoleM;
    ConsoleM.HPLUART -> HPLUARTC;
}
