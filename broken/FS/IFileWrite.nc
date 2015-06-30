interface IFileWrite {
  command void new(bool check);
  event void newDone(fileresult_t result);

  command fileblock_t firstBlock();

  command void sync();
  command void metaSync();
  event void syncDone(fileresult_t result);

  // Note: This *does not* sync (just changes firstBlock result). It's
  // use is optional.
  command void close();

  command void write(void *buffer, filesize_t n);
  event void writeDone(filesize_t nWritten, fileresult_t result);
}
