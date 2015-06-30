interface IFileBlock {
  command void write(fileblock_t block, fileblockoffset_t offset,
		     void *data, fileblockoffset_t n);
  event void writeDone(fileresult_t result);

  command void sync(fileblock_t block);
  event void syncDone(fileresult_t result);

  command void flush(fileblock_t block);
  event void flushDone(fileresult_t result);

  command void read(fileblock_t block, fileblockoffset_t offset,
		    void *data, fileblockoffset_t n);
  event void readDone(fileresult_t result);
}
