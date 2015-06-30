/**
 * Rename a file
 */
interface FileRename {
  /**
   * Rename a file. If a file called <code>newName</code> exists, it is
   * deleted.
   * @param oldName Name of file to rename. Must not be stack allocated.
   * @param newName New name of file. Must not be stack allocated.
   * @return 
   *   SUCCESS: attempt proceeds, <code>renamed</code> will be signaled<br>
   *   FAIL: filesystem is busy or newName is ""
   */
  command result_t rename(const char *oldName, const char *newName);

  /**
   * Signaled at the end of a file rename attempt
   * @param result
   *   FS_OK: file was renamed<br>
   *   FS_ERROR_xxx: rename failure cause
   * @return Ignored
   */
  event result_t renamed(fileresult_t result);
}
