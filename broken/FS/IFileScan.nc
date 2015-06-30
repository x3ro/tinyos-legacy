interface IFileScan {
  command void scanFS(fileblock_t root);
  event void scanned(fileresult_t result);
  event void anotherFile();
}
