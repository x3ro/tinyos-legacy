interface IFileRoot {
  command void locateRoot();
  event void emptyMatchbox();
  event void possibleRoot(fileblock_t root, filemeta_t version);
  event filemeta_t currentVersion();
  event void located();
}
