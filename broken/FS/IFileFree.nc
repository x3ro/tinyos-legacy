interface IFileFree {
  command fileblock_t nFreeBlocks();
  command void setReserved(fileblock_t n);
  command fileblock_t allocate();
  command void free(fileblock_t n);
  command void setFreePtr(fileblock_t n);
  command void reserve(fileblock_t n); /* mark block n as allocated */
  command bool inuse(fileblock_t n);
  command void freeall();
}
