includes IFS;
interface IFileBlockMeta {
  command void read(fileblock_t block, bool check);
  event void readDone(fileblock_t nextBlock, fileblockoffset_t lastByte,
		      fileresult_t result);

  command void write(fileblock_t block, bool check, bool isRoot,
		     fileblock_t nextBlock, fileblockoffset_t lastByte);
  event void writeDone(fileresult_t result);
}
