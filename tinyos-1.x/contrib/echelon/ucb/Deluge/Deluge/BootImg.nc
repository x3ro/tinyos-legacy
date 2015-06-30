
/**
 * BootImg.nc - Generic methods for writing a boot image compatible
 * with an arbitrary boot loader.
 *
 * @author Jonathan Hui <jwhui@cs.berkeley.edu>
 * @since  0.1
 */

interface BootImg {

  /**
   * Sets the program id of the boot image. The responsibility of
   * keeping the pid constant while writing the boot image line by
   * line is placed on the user.
   *
   * @param pid  program id of the image to write
   * @return     <code>SUCCESS</code> if the command succeeds;
   *             <code>FAIL</code> otherwise.
   * @since      0.1
   */
  command result_t setImgAttributes(uint16_t pid, uint32_t imgSize);

  /**
   * Read boot image data.
   *
   * @param data    buffer to place read data
   * @param offset  offset in bytes to start read
   * @param length  amount of data to read
   * @return        <code>SUCCESS</code> if read command succeeds;
   *                <code>FAIL</code> otherwise.
   * @since 0.1
   */
  command result_t read(uint8_t* data, uint32_t offset, uint16_t length);

  /**
   * Notify that read of boot image data is done.
   *
   * @param result  <code>SUCCESS</code> if read completed successfully;
   *                <code>FAIL</code> otherwise.
   * @return        <code>SUCCESS</code> if event is handled successfully;
   *                <code>FAIL</code> otherwise.
   * @since 0.1
   */
  event   result_t readDone(result_t result);

  /**
   * Write boot imge data.
   *
   * @param data    buffer containing data to write
   * @param offset  offset in bytes to start write
   * @param length  amount of data to write
   * @return        <code>SUCCESS</code> if write command succeeds;
   *                <code>FAIL</code> otherwise.
   * @since 0.1
   */
  command result_t write(uint8_t* data, uint32_t offset, uint16_t length);

  /**
   * Notify that write of boot image data is done.
   *
   * @param result  <code>SUCCESS</code> if write completed successfully;
   *                <code>FAIL</code> otherwise.
   * @return        <code>SUCCESS</code> if event is handled successfully;
   *                <code>FAIL</code> otherwise.
   * @since 0.1
   */
  event   result_t writeDone(result_t result);

  /**
   * Sync boot image data with stable store.
   *
   * @return  <code>SUCCESS</code> if sync command succeeds;
   *          <code>FAIL</code> otherwise.
   * @since 0.1
   */
  command result_t sync();

  /**
   * Notify that sync of image data is done.
   *
   * @param result  <code>SUCCESS</code> if sync completes successfully;
   *                <code>FAIL</code> otherwise.
   * @return        <code>SUCCESS</code> if event is handled successfully;
   *                <code>FAIL</code> otherwise.
   */
  event   result_t syncDone(result_t result);
}
