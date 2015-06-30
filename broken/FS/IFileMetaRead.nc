interface IFileMetaRead {
  command void read();
  command void readNext();
  event void nextFile(struct fileEntry *file, fileresult_t result);
}
