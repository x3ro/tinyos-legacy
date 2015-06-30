interface IFileWrite2 {
  command void open(fileblock_t first, bool check);
  event void openDone(fileresult_t result);

  command void seekEnd();
  event void seekDone(filesize_t size, fileresult_t result);

  command void truncate();
  event void truncated(fileblock_t freeBlocks, fileresult_t result);

  command void reserve(filesize_t newSize);
  event void reserved(filesize_t reservedSize, fileresult_t result);
}
