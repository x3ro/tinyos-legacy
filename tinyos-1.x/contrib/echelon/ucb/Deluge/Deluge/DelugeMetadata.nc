
/**
 * DelugeMetadata.nc - Manages metadata.
 *
 * @author Jonathan Hui <jwhui@cs.berkeley.edu>
 * @since  0.1
 */

includes DelugeMetadata;

interface DelugeMetadata {

  /**
   * Returns the most recent version number whether or not the image
   * is completely downloaded.
   *
   * @return  the version number of the most recent image
   * @since   0.1
   */
  command imgvnum_t getVNum();

  command imgvnum_t getPrevVNum();

  /**
   * Returns the number of pages in the most recent image whether or
   * not the image is completely downloaded.
   *
   * @return  the number of pages in the most recent image
   * @since   0.1
   */
  command uint16_t   getNumPgs();

  /**
   * Returns the number of pages complete in the most recent
   * image. Page <code>i</code> is considered complete if all of the
   * data for page <code>i</code> has been received and all pages
   * between <code>0</code> and <code>i</code>, inclusive, are also
   * complete.
   *
   * @return  the number of pages complete in the most recent image
   * @since   0.1
   */
  command uint16_t   getNumPgsComplete();

  command uint32_t getImgSize();

  /**
   * Returns a summary of the image including the version number and
   * the number of pages complete.
   *
   * @return  the image summary
   * @since   0.1
   */
  command result_t  getImgSummary(DelugeImgSummary* pResult);

  /**
   * Returns the first incomplete page that should be requested.
   *
   * @return  the page number of the first incomplete page to acquire
   * @since   0.1
   */
  command result_t  getNextIncompletePage(uint16_t* pResult);

  /**
   * Compares a given summary with the current image to check if the
   * summary represents a newer image.
   *
   * @param summary  the summary of the image to compare
   * @return         <code>TRUE</code> if <code>summary</code> represents 
   *                 an image which is newer;
   *                 <code>FALSE</code> otherwise.
   * @since          0.1
   */
  command bool      isNewer(DelugeImgSummary* summary);

  command bool isUpdating();

  /**
   * Update the metadata to reflect that a new page has been received.
   *
   * @param pgNum  the number of the page which has been received
   * @return       <code>SUCCESS</code> if the update happened successfully;
   *               <code>FAIL</code> otherwise.
   * @since        0.1
   */
  command result_t  pgFlushed(uint16_t pgNum);

  /**
   * Generates diff information for an older version. This should
   * always be called with <code>pktNum</code> starting at
   * <code>0</code> and incrementing by one until the method returns
   * <code>SUCCESS</code>. This is necessary since diffs for large
   * programs may require multiple packets.
   *
   * @param pResult  the buffer to place diff information
   * @param oldVNum  the version number to diff
   * @param pktNum   the packet number of the diff to generate
   * @return         <code>SUCCESS</code> if the page diff s generated
   *                 for the last packet;
   *                 <code>FAIL</code> otherwise.
   * @since          0.1
   */
  command result_t  generatePageDiff(DelugeImgDiff* pResult, 
				     imgvnum_t oldVNum, uint8_t pktNum);

  /**
   * Apply a given page diff to update metadata and figure out which
   * data pages are need to be downloaded. Also initiates sync of
   * metadata to stable store.
   *
   * @param pResult  the page diff to apply
   * @return         <code>SUCCESS</code> if the page diff has been 
   *                 applied successfully and the sync initiation also 
   *                 is successful;
   *                 <code>FAIL</code> otherwise.
   * @since          0.1
   */
  command result_t  applyPageDiff(DelugeImgDiff* pResult);

  /**
   * Notify that sync of changed metadata has completed.
   *
   * @param result  <code>SUCCESS</code> if the diff has been applied 
   *                successfully;
   *                <code>FAIL</code> otherwise.
   * @return        <code>SUCCESS</code> if the event is handled successfully;
   *                <code>FAIL</code> otherwise.
   * @since         0.1
   */
  event   result_t  applyPageDiffDone(result_t result);

  /**
   * Notify that metadata has been read from stable store and is ready
   * to be used. Only occurs when node is starting up to restore
   * metadata in RAM.
   *
   * @param result  <code>SUCCESS</code> if the metadata has been read 
   *                successfully;
   *                <code>FAIL</code> otherwise.
   * @return        <code>SUCCESS</code> if the event is handled successfully;
   *                <code>FAIL</code> otherwise.
   * @since         0.1
   */
  event   result_t  ready(result_t result);

}
