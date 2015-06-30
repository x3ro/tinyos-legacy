/**
 * Delete a file
 */
interface FileDelete {
  /**
   * Delete a file
   * @param filename Name of file to delete. Must not be stack allocated.
   * @return 
   *   SUCCESS: attempt proceeds, <code>deleted</code> will be signaled<br>
   *   FAIL: filesystem is busy
   */
  command result_t delete(const char *filename);

  /**
   * Signaled at the end of a file delete attempt
   * @param result
   *   FS_OK: file was deleted<br>
   *   FS_ERROR_xxx: delete failure cause
   * @return Ignored
   */
  event result_t deleted(fileresult_t result);
}
