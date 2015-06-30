
/**
 * NetProg.nc - Top level interface for network programming
 * integration with applications.
 *
 * @author Jonathan Hui <jwhui@cs.berkeley.edu>
 * @since  0.1
 */

interface NetProg {
  /**
   * Returns a list of version numbers available to boot from.
   *
   * @param vNums  the version numbers available to boot from (this buffer must 
   *               be of length DELUGE_MAX_VNUMS_AVAILABLE)
   * @return       <code>SUCCESS</code> if the command completed successfully;
   *               <code>FAIL</code> otherwise.
   * @since        0.1
   */
  command result_t getVersionsAvailable(uint16_t* vNums);

  command uint16_t getFlashVersion();
  command uint16_t getExecutingVersion();

  /**
   * Prepares a boot image which matches the given version number.
   *
   * @param vNum  the version number of the image to prepare
   * @return      <code>SUCCESS</code> if the version number is available and 
   *              start of preparation has succeeded;
   *              <code>FAIL</code> otherwise.
   * @since       0.1
   */
  command result_t prepBootImg(uint16_t vNum);

  /**
   * Notify that the preparation of the boot image is complete.
   *
   * @param result  <code>SUCCESS</code> if preparation of the boot image has
   *                completed successfully;
   *                <code>FAIL</code> otherwise.
   * @return        <code>SUCCESS</code> if the event is handled successfully;
   *                <code>FAIL</code> otherwise.
   * @since         0.1
   */
  //event result_t prepBootImgDone(result_t result);

  

}
