/*
 * file:        FalC.nc
 * description: This abstracts away the flash device
 */

includes platform;

configuration FalC {
    provides {
    	interface GenericFlash[uint8_t id];
        interface StdControl;
    }
#ifdef FLASH_DEBUG
    uses interface Console;
#endif
}

/* Using the separate configuration file lets us #ifdef the wiring for
 *the serial debug console.
 */
implementation {
#ifndef PLATFORM_MICA2_NOR

    /* UMass NAND */
    components PageNANDM,
               NANDFlashM;

    GenericFlash = NANDFlashM.GenericFlash;
    NANDFlashM.PageNAND -> PageNANDM.PageNAND;
    StdControl = PageNANDM.StdControl;

#else

    /* Mica2 NOR */
    components PageEEPROMC, 
               FlashM, LedsC;

    GenericFlash = FlashM.GenericFlash;
    FlashM.PageEEPROM -> PageEEPROMC.PageEEPROM[unique("PageEEPROM")];
    StdControl = PageEEPROMC.StdControl;
    FlashM.Leds -> LedsC;
#ifdef FLASH_DEBUG
    Console = FlashM.Console;
#endif

#endif
}
