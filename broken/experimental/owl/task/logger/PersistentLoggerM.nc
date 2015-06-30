includes PageEEPROM;
includes ByteEEPROMInternal;
module PersistentLoggerM
{
  provides {
    interface AllocationReq[uint8_t clientId];
    interface IPersistent;
  }
  uses {
    interface PageEEPROM;
    interface AllocationReq as Alloc[uint8_t clientId];
    command RegionSpecifier *getRegion(uint8_t id, bool check);
  }
}
implementation
{
  enum {
    NREGIONS = uniqueCount("ByteEEPROM"),
    PAGE_SIZE = 1 << TOS_EEPROM_PAGE_SIZE_LOG2,
    PAGE_SIZE_MASK = PAGE_SIZE - 1,

    PERSISTENT_MAGIC = 0x4253,
    APPEND_MAGIC = (uint32_t)-1,
    NO_RECORD = PAGE_SIZE // marker that there's no record starting on this
			  // page
  };

  struct pageinfo {
    uint16_t magic;
    eeprompageoffset_t lastRecordOffset;
    uint16_t crc;
  } metadata;

  eeprompage_t firstPage, lastPage, tryPage;
  eeprompageoffset_t lastRecordOffset;
  uint8_t clients;

  void alloc(uint8_t id) {
    (call getRegion(id, FALSE))->appendOffset = APPEND_MAGIC;
    clients++;
  }

  void locateEnds();

  // Interpose on AllocationReq to find out which regions are persistent
  // Saves state in the append offset and tryPage
  command result_t AllocationReq.request[uint8_t id](uint32_t numBytesReq) {
    alloc(id);
    return call Alloc.request[id](numBytesReq);
  }

  command result_t AllocationReq.requestAddr[uint8_t id](uint32_t byteAddr, uint32_t numBytesReq) {
    alloc(id);
    return call Alloc.requestAddr[id](byteAddr, numBytesReq);
  }

  task void doLocating() {
    locateEnds();
  }

  event result_t Alloc.requestProcessed[uint8_t id](result_t success) {
    RegionSpecifier *region = call getRegion(id, FALSE);

    if (region->appendOffset == APPEND_MAGIC)
      {
	if (!success)
	  region->appendOffset = 0;
	if (--clients == 0)
	  // This happens in start. Can't start reading until start completes.
	  post doLocating();
      }
    return SUCCESS;
  }

  void completeLocate(result_t ok) {
    signal AllocationReq.requestProcessed[clients++](ok);
    locateEnds();
  }

  void located() {
    RegionSpecifier *region = call getRegion(clients, FALSE);
    uint32_t offset;

    // firstPage will end up being 1 past the last valid page, i.e.,
    // == to the initial page if there are no valid pages
    if (firstPage == region->startByte >> TOS_EEPROM_PAGE_SIZE_LOG2)
      offset = 1;
    else
      offset = ((uint32_t)(firstPage - 1) << TOS_EEPROM_PAGE_SIZE_LOG2) -
	region->startByte + lastRecordOffset + 1;
    region->appendOffset = offset;

    completeLocate(SUCCESS);
  }

  void binaryLocate() {
    if ((int)lastPage - (int)firstPage < 0)
      located();
    else
      {
	tryPage = firstPage + ((lastPage - firstPage + 1) >> 1);

	if (!call PageEEPROM.read(tryPage, PAGE_SIZE, &metadata,
				  sizeof metadata))
	  completeLocate(FAIL);
      }
  }

  void locateGreaterThan() {
    lastRecordOffset = metadata.lastRecordOffset;
    firstPage = tryPage + 1;
    binaryLocate();
  }

  void locateLessThan() {
    lastPage = tryPage - 1;
    binaryLocate();
  }

  void locateCrc(uint16_t crc) {
    if (crc == metadata.crc)
      locateGreaterThan();
    else
      locateLessThan();
  }

  event result_t PageEEPROM.readDone(result_t success) {
    if (metadata.magic == PERSISTENT_MAGIC)
      call PageEEPROM.computeCrc(tryPage, 0,
				 PAGE_SIZE + offsetof(struct pageinfo, crc));
    else
      locateLessThan();
    return SUCCESS;
  }

  void locateEnd() {
    RegionSpecifier *region = call getRegion(clients, FALSE);

    if (!region)
      {
	completeLocate(FAIL);
	return;
      }

    firstPage = region->startByte >> TOS_EEPROM_PAGE_SIZE_LOG2;
    lastPage = (region->stopByte - 1) >> TOS_EEPROM_PAGE_SIZE_LOG2;
    binaryLocate();
  }

  void locateEnds() {
    for (; clients < NREGIONS; clients++)
      if ((call getRegion(clients, FALSE))->appendOffset == APPEND_MAGIC)
	{
	  locateEnd();
	  return;
	}
  }

  command result_t IPersistent.finishPage(eeprompage_t lp, eeprompageoffset_t lr) {
    tryPage = lp;
    metadata.lastRecordOffset = lr;
    return call PageEEPROM.computeCrc(lp, 0, PAGE_SIZE);
  }

  event result_t PageEEPROM.computeCrcDone(result_t result, uint16_t crc) {
    if (clients < NREGIONS)
      locateCrc(crc);
    else
      {
	uint8_t i, *md;

	metadata.magic = PERSISTENT_MAGIC;

	// Include metadata in crc
	md = (uint8_t *)&metadata;
	for (i = 0; i < offsetof(struct pageinfo, crc); i++)
	  crc = crcByte(crc, md[i]);
	metadata.crc = crc;

	// And save it
	if (!call PageEEPROM.write(tryPage, PAGE_SIZE, md, sizeof metadata))
	  signal IPersistent.finishPageDone(FAIL);
      }
    return SUCCESS;
  }

  event result_t PageEEPROM.writeDone(result_t success) {
    signal IPersistent.finishPageDone(success);
    return SUCCESS;
  }

  // unused
  event result_t PageEEPROM.syncDone(result_t result) { 
    return SUCCESS;
  }

  event result_t PageEEPROM.flushDone(result_t result) {
    return SUCCESS;
  }

  event result_t PageEEPROM.eraseDone(result_t success) {
    return SUCCESS;
  }

  default event result_t AllocationReq.requestProcessed[uint8_t id](result_t success) {
    return SUCCESS;
  }
}
