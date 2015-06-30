
/**
 * DelugePageTransfer.nc - Handles the transfer of individual data
 * pages between neighboring nodes.
 *
 * @author Jonathan Hui <jwhui@cs.berkeley.edu>
 * @since  0.1
 */

interface DelugePageTransfer {

  /**
   * Tell the <code>DelugePageTransfer</code> to start requesting data
   * from a given node. If <code>DelugePageTransfer</code> is already
   * actively requesting data from a different node, it will attempt
   * to request data from the given node only if the request fails.
   *
   * @param sourceAddr  the address of a node to request new data from
   * @return            <code>SUCCESS</code>
   *                    <code>FAIL</code> otherwise.
   * @since 0.1
   */
  command result_t setNewSource(uint16_t sourceAddr);

  /**
   * Notify that transferring of data pages has begun.
   *
   * @return <code>SUCCESS</code> if the event is handled successfully;
   *         <code>FAIL</code> otherwise.
   * @since 0.1
   */
  event   result_t transferBegin();

  /**
   * Notify that transferring of data pages has completed.
   *
   * @return <code>SUCCESS</code> if the event is handled successfully;
   *         <code>FAIL</code> otherwise.
   * @since 0.1
   */
  event   result_t transferDone(bool doneReceiving);

  /**
   * Notify that a new data page has been received and is available
   * for sending.
   *
   * @return <code>SUCCESS</code> if the event is handled successfully;
   *         <code>FAIL</code> otherwise.
   * @since 0.1
   */
  event   result_t receivedNewData();

  event result_t overheardData(uint16_t pgNum);
}
