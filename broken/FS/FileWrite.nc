/**
 * File reading interface, supports appending writes.
 */

interface FileWrite {
  /**
   * open a file for sequential reads.
   * @param filename Name of file to open. Must not be stack allocated.
   * @param flags: open options, an or (|) of FS_Fxxx constants.<br>
   *   <code>FS_FTRUNCATE</code> Truncate file if it exists<br>
   *   <code>FS_FCREATE</code> Create file if it doesn't exist
   * @param truncate TRUE if file should be truncated if it exists
   * @return 
   *   SUCCESS: attempt proceeds, <code>opened</code> will be signaled<br>
   *   FAIL: filesystem is busy, another file is already open for writing,
   *     filename is ""
   */
  command result_t open(const char *filename, uint8_t flags);

  /**
   * Signaled at the end of a file open attempt
   * @param fileSize size of file (if file was opened)
   * @param reservedSize space reserved for files (if file was opened)
   *   -- see <code>reserve</code>
   * @param result
   *   FS_OK: file was opened<br>
   *   FS_ERROR_xxx: open failure cause
   * @return Ignored
   */
  event result_t opened(filesize_t fileSize, fileresult_t result);

  /**
   * close file currently open for writing
   * @return
   *   SUCCESS: attempts proceeds, <code>closed</code> will be signaled<br>
   *   FAIL: no file was open for writing, or a close/append/reserve/sync
   *     is in progress
   */
  command result_t close();

  /**
   * Signaled at the end of a file close. File is closed in all cases,
   *   including failure (but in case of failure some data may have been lost).
   * @param result
   *   FS_OK: file was closed without problems. All data has been comitted to
   *     stable storage.<br>
   *   FS_ERROR_xxx: close failure cause
   * @return Ignored
   */
  event result_t closed(fileresult_t result);

  /**
   * Write bytes sequentially to end of open file.
   * @param buffer Data to write
   * @param n Number of bytes to write
   * @return
   *   SUCCESS: attempt proceeds, <code>appended</code> will be signaled<br>
   *   FAIL: no file was open for writing, or a close/append/reserve/sync
   *     is in progress
   */
  command result_t append(void *buffer, filesize_t n);

  /**
   * Signaled when a <code>append</code> completes
   * @param buffer Buffer that was passed to <code>append</code>
   * @param nWritten Number of bytes actually written
   *   but result will still be FS_OK)
   * @param result
   *   FS_OK: write was successful
   *   FS_ERROR_xxx: write failure cause. Some bytes may have been written
   *     (as reported by the value of <code>nWritten</code>
   * @return Ignored
   */
  event result_t appended(void *buffer, filesize_t nWritten,
			  fileresult_t result);

  /**
   * Reserve space for the currently open file to be <code>newSize</code>
   * bytes long. <code>append</code>s that do not make the file take
   * more than <code>newSize</code> bytes will not fail with FS_ERROR_NOSPACE.
   * Note: you can find the reserved size of a file by requesting a reserve
   * with a newSize of 0. The <code>reserved</code> event will indicate the
   * space currently reserved.
   * @param newSize Size file is expected to grow to
   * @return
   *   SUCCESS: attempt proceeds, <code>reserved</code> will be signaled<br>
   *   FAIL: no file was open for writing, or a close/append/reserve/sync
   *     is in progress
   */
  command result_t reserve(filesize_t newSize);

  /**
   * Signaled at the end of a space reservation attempt
   * @param maxSize New reserved size (>= requested size)
   * @param result
   *   FS_OK: space was successfully reserved<br>
   *   FS_ERROR_xxx: failure cause
   * @return Ignored
   */
  event result_t reserved(filesize_t reservedSize, fileresult_t result);

  /**
   * Ensure data appended is comitted to stable storage.
   * @return
   *   SUCCESS: attempt proceeds, <code>synced</code> will be signaled<br>
   *   FAIL: no file was open for writing, or a close/append/reserve/sync
   *     is in progress
   */
  command result_t sync();

  /**
   * Signaled at the end of a sync attempt
   * @param result
   *   FS_OK: sync was successful<br>
   *   FS_ERROR_xxx: failure cause
   * @return Ignored
   */
  event result_t synced(fileresult_t result);
}
