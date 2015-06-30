
/**
 * DelugeMetadataStableStore - Generic interface for reading and
 * writing metadata to and from stable storage.
 *
 * @author Jonathan Hui <jwhui@cs.berkeley.edu>
 * @since  0.1
 */

interface DelugeMetadataStableStore {

  /**
   * Reads metadata information for stable storage.
   *
   * @param metadata  the buffer to put read metadata
   * @return          <code>SUCCESS</code> if the read request is successful;
   *                  <code>FAIL</code> otherwise.
   * @since           0.1
   */
  command result_t getMetadata(DelugeMetadata* metadata);

  /**
   * Notify that the read of metadata has completed.
   *
   * @param result  <code>SUCCESS</code> if the read completed successfuly;
   *                <code>FAIL</code> otherwise.
   * @return        <code>SUCCESS</code> if the event is handled successfully;
   *                <code>FAIL</code> otherwise.
   * @since         0.1
   */
  event   result_t getMetadataDone(result_t result);

  /**
   * Write metadata to stable storage.
   *
   * @param metadata  the metadata to write to stable storage
   * @return          <code>SUCCESS</code> if the write request is successful;
   *                  <code>FAIL</code> otherwise.
   * @since 0.1
   */
  command result_t writeMetadata(DelugeMetadata* metadata);

  /**
   * Notify that the write of metadata has completed
   *
   * @param result  <code>SUCCESS</code> if the write requested completed 
   *                successfully;
   *                <code>FAIL</code> otherwise.
   * @return        <code>SUCCESS</code> if the event is handled successfully;
   *                <code>FAIL</code> otherwise.
   * @since         0.1
   */
  event   result_t writeMetadataDone(result_t result);
}
