interface IFileBlockErase {
  command void erase(fileblock_t block);
  event void eraseDone(result_t result);
}
