includes IFS;
module Blocks {
  provides {
    interface IFileBlock[uint8_t clientId];
    interface IFileBlockErase[uint8_t clientId];
    interface IFileBlockMeta[uint8_t clientId];
  }
  uses {
    interface PageEEPROM;
  }
#include "massert.h"
}
implementation {
  struct metadata {
    // Note: LocateRoot has the rootMarker details hardwired
    unsigned int rootMarker : IFS_ROOT_MARKER_BITS;
    unsigned int nextBlock : 12;
    unsigned int lastByte : 9;
    uint8_t check;
    uint16_t crc;
  };

  enum {
    S_READ,
    S_WRITE,
    S_READ_META,
    S_READ_METACHECK,
    S_WRITE_META
  };

  uint8_t state;
  uint8_t client;
  struct metadata metadata;
  eeprompage_t page;

  uint8_t metadataCheck(struct metadata *m) {
    uint8_t *bytes = (uint8_t *)m;

    return ~(bytes[0] + bytes[1] + bytes[2]);
  }

  fileresult_t makeFileresult(result_t result) {
    switch (result)
      {
      case FAIL:
	return FS_ERROR_HW;
      default:
	return FS_OK;
      }
  }


  void read(uint8_t id, fileblock_t block, fileblockoffset_t o,
	    void *data, fileblockoffset_t n) {
    client = id;
    page = block;
    call PageEEPROM.read(block, o, data, n);
  }


  void write(uint8_t id, fileblock_t block, fileblockoffset_t o, 
	     void *data, fileblockoffset_t n) {
    client = id;
    page = block;
    call PageEEPROM.write(block, o, data, n);
  }

  // Read

  command void IFileBlock.read[uint8_t id](fileblock_t block,
					   fileblockoffset_t offset,
					   void *data, fileblockoffset_t n) {
    state = S_READ;
    read(id, block, offset, data, n);
  }

  void metaReadDone(fileresult_t fresult);

  event result_t PageEEPROM.readDone(result_t result) {
    fileresult_t fresult = makeFileresult(result);

    switch (state)
      {
      case S_READ:
	signal IFileBlock.readDone[client](fresult); 
	break;
      case S_READ_META: case S_READ_METACHECK:
	metaReadDone(fresult);
	break;
      }

    return SUCCESS;
  }


  // Write

  command void IFileBlock.write[uint8_t id](fileblock_t block,
					    fileblockoffset_t offset,
					    void *data, fileblockoffset_t n) {
    state = S_WRITE;
    write(id, block, offset, data, n);
  }

  event result_t PageEEPROM.writeDone(result_t result) {
    fileresult_t fresult = makeFileresult(result);

    switch (state)
      {
      case S_WRITE:
	signal IFileBlock.writeDone[client](fresult); 
	break;
      case S_WRITE_META:
	signal IFileBlockMeta.writeDone[client](fresult);
	break;
      }
    return SUCCESS;
  }


  // Sync

  command void IFileBlock.sync[uint8_t id](fileblock_t block) {
    client = id;
    call PageEEPROM.sync(block);
  }

  event result_t PageEEPROM.syncDone(result_t result) {
    signal IFileBlock.syncDone[client](makeFileresult(result));
    return SUCCESS;
  }

  
  // Flush

  command void IFileBlock.flush[uint8_t id](fileblock_t block) {
    client = id;
    call PageEEPROM.flush(block);
  }

  event result_t PageEEPROM.flushDone(result_t result) {
    signal IFileBlock.flushDone[client](makeFileresult(result));
    return SUCCESS;
  }


  // Erase

  command void IFileBlockErase.erase[uint8_t id](fileblock_t block) {
    client = id;
    call PageEEPROM.erase(block, TOS_EEPROM_DONT_ERASE);
  }

  event result_t PageEEPROM.eraseDone(result_t result) {
    signal IFileBlockErase.eraseDone[client](makeFileresult(result));
    return SUCCESS;
  }



  // Metadata
  // --------

  void metaRead(uint8_t id, fileblock_t block, uint8_t count) {
    read(id, block, IFS_OFFSET_METADATA, &metadata, count);
  }

  void metaWrite(uint8_t count) {
    metadata.check = metadataCheck(&metadata);
    write(client, page, IFS_OFFSET_METADATA, &metadata, count);
  }

  // Metadata Read

  command void IFileBlockMeta.read[uint8_t id](fileblock_t block, bool check) {
    uint8_t count;

    if (check)
      {
	state = S_READ_METACHECK;
	count = sizeof(struct metadata);
      }
    else
      {
	state = S_READ_META;
	count = offsetof(struct metadata, crc);
      }
    metaRead(id, block, count);
  }

  void metaReadDone(fileresult_t fresult) {
    if (metadata.check != metadataCheck(&metadata) && fresult == FS_OK)
      fresult = FS_ERROR_BAD_DATA;

    if (fresult == FS_OK && state == S_READ_METACHECK)
      {
	call PageEEPROM.computeCrc(page, 0, metadata.lastByte);
	return;
      }
    signal IFileBlockMeta.readDone[client]
      (metadata.nextBlock, metadata.lastByte, fresult);
  }

  event result_t PageEEPROM.computeCrcDone(result_t result, uint16_t crc) {
    fileresult_t fresult = makeFileresult(result);

    if (state == S_READ_METACHECK)
      {
	if (metadata.crc != crc && fresult == FS_OK)
	  fresult = FS_ERROR_BAD_DATA;

	state = S_READ_META;
	metaReadDone(fresult);
      }
    else // S_WRITE_META w/ check on
      if (fresult == FS_OK)
	{
	  metadata.crc = crc;
	  metaWrite(sizeof(struct metadata));
	}
      else
	signal IFileBlockMeta.writeDone[client](fresult);
    return SUCCESS;
  }

  // Metadata Write

  command void IFileBlockMeta.write[uint8_t id](fileblock_t block, bool check, bool isRoot, fileblock_t nextBlock, fileblockoffset_t lastByte) {
    state = S_WRITE_META;
    page = block;
    client = id;

    metadata.rootMarker = isRoot ? IFS_ROOT_MARKER : 0;
    metadata.nextBlock = nextBlock;
    metadata.lastByte = lastByte;
    metadata.check = metadataCheck(&metadata);

    if (check)
      call PageEEPROM.computeCrc(block, 0, lastByte);
    else
      metaWrite(offsetof(struct metadata, crc));
  }

  // Default handlers. Should never be called.

  default event void IFileBlock.readDone[uint8_t id](fileresult_t result) { 
    assert(0);
  }
  default event void IFileBlock.writeDone[uint8_t id](fileresult_t result) {
    assert(0);
  }
  default event void IFileBlock.syncDone[uint8_t id](fileresult_t result) {
    assert(0);
  }
  default event void IFileBlock.flushDone[uint8_t id](fileresult_t result) {
    assert(0);
  }
  default event void IFileBlockErase.eraseDone[uint8_t id](fileresult_t result) {
    assert(0);
  }
  default event void IFileBlockMeta.readDone[uint8_t id]
    (fileblock_t nextBlock, fileblockoffset_t lastByte, fileresult_t result) {
    assert(0);
  }
  default event void IFileBlockMeta.writeDone[uint8_t id](fileresult_t result) {
    assert(0);
  }
}
