/*
 * file:        PageNANDC.nc
 * description: Component for NAND Flash driver
 */

configuration PageNANDC {
    provides {
        interface StdControl;
	interface PageNAND;
    }
}

/* Using the separate configuration file lets us #ifdef the wiring for
 *the serial debug console.
 */
implementation {
    components PageNANDM;

#ifdef DEBUG_NAND
    components ConsoleC;
#endif

    StdControl = PageNANDM;
    PageNAND = PageNANDM;

#ifdef DEBUG_NAND
    PageNANDM.Console -> ConsoleC;
#endif

}

    
