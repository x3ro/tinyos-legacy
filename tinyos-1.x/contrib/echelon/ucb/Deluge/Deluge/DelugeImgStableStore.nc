
/**
 * DelugeImgStableStore - Generic interface for reading and writing
 * image data to and from stable storage.
 *
 * @author Jonathan Hui <jwhui@cs.berkeley.edu>
 * @since  0.1
 */

interface DelugeImgStableStore {

  /**
   * Reads image data from stable storage.
   *
   * @param offset  the offset in the image to begin read of data
   * @param dest    the buffer to put read image data
   * @param length  the number of bytes to read
   * @return        <code>SUCCESS</code> if the read request is successful;
   *                <code>FAIL</code> otherwise.
   * @since         0.1
   */
  command result_t getImgData(uint32_t offset, uint8_t* dest, uint32_t length);

  /**
   * Notify that the read of image data has completed.
   *
   * @param result  <code>SUCCESS</code> if the read completed successfuly;
   *                <code>FAIL</code> otherwise.
   * @return        <code>SUCCESS</code> if the read request completed
   *                successfully;
   *                <code>FAIL</code> otherwise.
   * @since         0.1
   */
  event   result_t getImgDataDone(result_t result);

  command result_t setImgAttributes(uint16_t pid, uint32_t imgSize);

  /**
   * Write image data to stable storage.
   *
   * @param offset  the offset in the image to begin write of data
   * @param source  the image data to write to stable storage
   * @param length  the number of bytes to read
   * @return        <code>SUCCESS</code> if the write request is successful;
   *                <code>FAIL</code> otherwise.
   * @since         0.1
   */
  command result_t writeImgData(uint32_t offset, uint8_t* source, uint32_t length);

  /**
   * Notify that the write of image data has completed
   *
   * @param result  <code>SUCCESS</code> if the write requested completed 
   *                successfully;
   *                <code>FAIL</code> otherwise.
   * @return        <code>SUCCESS</code> if the event is handled successfully;
   *                <code>FAIL</code> otherwise.
   * @since         0.1
   */
  event   result_t writeImgDataDone(result_t result);
}
