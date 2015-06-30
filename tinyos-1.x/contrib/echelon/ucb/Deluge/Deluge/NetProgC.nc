
/**
 * NetProgC Configuration - Top level component connecting services
 * required for network programming.
 *
 * @author Jonathan Hui
 */

configuration NetProgC {
  provides {
    interface NetProg;
    interface StdControl;
  }
}

implementation {
  components
    DelugeC;

  StdControl = DelugeC;
  NetProg = DelugeC;
}
