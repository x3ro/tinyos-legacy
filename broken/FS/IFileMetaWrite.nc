interface IFileMetaWrite {
  command void write();
  command void writeFile(const char *filename, fileblock_t firstBlock);
  event void writeReady();

  command void writeComplete(fileresult_t callerResult);
  event void writeCompleted(fileresult_t result);

  command void deleteBlocks(fileblock_t firstBlock);
  event void blocksDeleted(fileresult_t result);
}
