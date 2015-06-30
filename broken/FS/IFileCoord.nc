interface IFileCoord {
  /**
   * Lock the filing system for a metadata operation
   * @return SUCCESS if locked
   *   FAIL if already locked
   */
  command result_t lock();

  /**
   * Unlock the filing system after a metadata operation completes.
   * Requires that the filing system is in the locked state
   * @return SUCCESS
   */
  command result_t unlock();
}
