/**
 * List files in filing system
 */
interface FileDir {
  /**
   * List names of all files in filing system. Filing system is busy
   * until FAIL is returned from <code>readNext</code> or no more
   * files remain.
   * @return 
   *   SUCCESS: files can be read with <code>readNext</code>
   *   FAIL: filesystem is busy
   */
  command result_t start();

  /**
   * Return next file in filing system
   *
   * @return
   *   SUCCESS: attempt proceeds, <code>nextFile</code> will be signaled
   *   FAIL: no file list operation is in progress.
   */
  command result_t readNext();

  /**
   * Report next file name. 
   * @param filename One of the files in the filing system if 
   *   <code>result</code> is FS_OK, NULL otherwise. The storage for
   *   filename only remains valid until the end of the event.
   * @param result
   *   FS_OK filename is the next file.
   *   FS_NO_MORE_FILES No more files.
   *   FS_ERROR_xxx Filing system data is corrupt.
   * @return
   *   SUCCESS: continue reporting file names<br>
   *   FAIL: abort the file lising operation<br>
   * If the <code>result</code> is an error or no more files, the file
   * listing operation terminates.
   */
  event result_t nextFile(const char *filename, fileresult_t result);

  /**
   * @return Number of bytes available in filing system.
   */
  command uint32_t freeBytes();
}
