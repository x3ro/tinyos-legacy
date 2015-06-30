interface IFileRead {
  command void open(fileblock_t firstBlock, fileblockoffset_t skipBytes,
		    bool check);

  command void read(void *buffer, filesize_t n);
  event void readDone(filesize_t nRead, fileresult_t result);

  command void getRemaining();
  event void remaining(filesize_t n, fileresult_t result);
}
