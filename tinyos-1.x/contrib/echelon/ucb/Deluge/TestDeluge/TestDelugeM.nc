
/**
 * TestDelugeM.nc - An application which installs the minimum services
 * required for network programming.
 *
 * @author Jonathan Hui <jwhui@cs.berkeley.edu>
 * @since  0.1
 */

module DelugeM {
  uses {
    interface Deluge;
  }
}

impelementation {

  event result_t prepBootImgDone(result_t result) {
    return SUCCESS;
  }

}
