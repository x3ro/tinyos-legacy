
/**
 * TestDeluge.nc - An application which installs the minimum services
 * required for network programming.
 *
 * @author Jonathan Hui <jwhui@cs.berkeley.edu>
 * @since  0.1
 */

configuration TestDeluge {
}
implementation {
  components
    Main,
    DelugeC;

  Main.StdControl -> DelugeC;
}
