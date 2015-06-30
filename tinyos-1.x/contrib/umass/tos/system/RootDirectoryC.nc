/*
 * file:        RootDirectoryC.nc
 * description: Root directory implementation
 */

/*
 * Root page implementation
 */

includes app_header;
includes common_header;

configuration RootDirectoryC {
    provides interface RootDirectory;
    provides interface StdControl;

    uses {
        interface Console;
        interface GenericFlash;
    }
}

implementation 
{
    components RootDirectoryM, LedsC, Crc8M;

    GenericFlash = RootDirectoryM.GenericFlash;
    RootDirectoryM.Crc8 -> Crc8M;
    RootDirectoryM.Leds -> LedsC;
    RootDirectory = RootDirectoryM.RootDirectory;
    StdControl = RootDirectoryM.StdControl;
    RootDirectoryM.Console = Console;
}
