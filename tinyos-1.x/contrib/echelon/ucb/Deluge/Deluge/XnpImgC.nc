
/**
 * XnpImgC.nc - Reads and writes srec data in Xnp compatible format.
 *
 * @author Jonathan Hui <jwhui@cs.berkeley.edu>
 * @since  0.1
 */

includes XnpImg;

configuration XnpImgC {
  provides {
    interface BootImg;
    interface StdControl;
  }
}
implementation {
  components
    PageEEPROMC as Flash,
    DelugeImgM as Format,
    LedsC;
  BootImg = Format;
  StdControl = Format;

  Format.Flash -> Flash.PageEEPROM[unique("PageEEPROM")];
  Format.Leds -> LedsC.Leds;
}
