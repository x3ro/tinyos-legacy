/*
 * file:        FalC.nc
 * description: Abstracts the platform flash
 *
 */

includes platform;

configuration FalC {
    provides {
    	interface GenericFlash[uint8_t id];
        interface StdControl;
    }
    uses interface Console;
}

/* Using the separate configuration file lets us #ifdef the wiring for
 *the serial debug console.
 */
implementation {
    components HALSTM25PC, FlashM;

    GenericFlash = FlashM.GenericFlash;
    FlashM.HALSTM25P -> HALSTM25PC.HALSTM25P[unique("Flash")];
    StdControl = HALSTM25PC.StdControl;
    Console = FlashM.Console;
}

    
