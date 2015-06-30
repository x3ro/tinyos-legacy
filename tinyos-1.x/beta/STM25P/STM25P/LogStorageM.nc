// $Id: LogStorageM.nc,v 1.4 2005/05/23 17:35:45 jwhui Exp $

/*									tab:2
 * "Copyright (c) 2000-2005 The Regents of the University  of California.  
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY OF
 * CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 */

/*
 * @author: Jonathan Hui <jwhui@cs.berkeley.edu>
 */

module LogStorageM {
  provides {
    interface Mount[logstorage_t logId];
    interface LogRead[logstorage_t logId];
    interface LogWrite[logstorage_t logId];
  }
  uses {
    interface SectorStorage[logstorage_t logId];
    interface Leds;
    interface Mount as ActualMount[logstorage_t logId];
    interface StorageManager[logstorage_t logId];
  }
}

implementation {

  enum {
    S_IDLE,
    S_MOUNT,
    S_ERASE,
    S_WRITE_SECTOR_HEADER,
    S_INIT_BLOCK_HEADER,
    S_COMMIT_BLOCK_HEADER,
    S_APPEND,
    S_SYNC,
    S_READ,
    S_SEEK,
  };
  
  LogSectorHeader sectorHeader;
  LogBlockHeader blockHeader;
  
  log_len_t rwLen, curLen, lastLen;
  void* rwData;
  
  uint8_t state;
  logstorage_t client;
  volume_id_t volumeId;

  log_cookie_t curReadCookie, curWriteCookie;
  log_block_addr_t curReadBlockLen, curWriteBlockPos;

  void signalDone(storage_result_t result) {

    uint8_t tmpState = state;

    state = S_IDLE;

    switch(tmpState) {
    case S_MOUNT: signal Mount.mountDone[client](result, volumeId); break;
    case S_ERASE: signal LogWrite.eraseDone[client](result); break;
    case S_APPEND: signal LogWrite.appendDone[client](result, rwData, rwLen); break;
    case S_SYNC: signal LogWrite.syncDone[client](result); break;
    case S_READ: signal LogRead.readDone[client](result, rwData, rwLen); break;
    case S_SEEK: signal LogRead.seekDone[client](result, curReadCookie); break;
    }

  }

  task void signalDoneTask() {
    signalDone(STORAGE_OK);
  }

  bool admitRequest(logstorage_t logId) {
    if (state != S_IDLE)
      return FALSE;
    client = logId;
    return TRUE;
  }

  result_t advanceCookie(log_cookie_t *curCookie) {

    log_cookie_t cookie = *curCookie;
    bool advancingWriteCookie = cookie == curWriteCookie;
    uint8_t newSector;
    
    while ( advancingWriteCookie || cookie < curWriteCookie ) {

      // if at beginning of sector, advance read cookie
      if (!(cookie % STM25P_SECTOR_SIZE))
	cookie += sizeof(LogSectorHeader);
      
      // read block header
      if (call SectorStorage.read[client](cookie, &blockHeader, sizeof(blockHeader)) 
	  == FAIL)
	return FAIL;

      // take block if:
      // 1) not allocated
      // 2) block is valid
      // 3) block current being written
      if ( !(~blockHeader.flags & LOG_BLOCK_ALLOCATED)
	   || (~blockHeader.flags & LOG_BLOCK_VALID)
	   || (!advancingWriteCookie && cookie >= curWriteCookie - curWriteBlockPos) ) {
	break;
      }
      
      // advance to next log block
      newSector = (cookie >> STM25P_SECTOR_SIZE_LOG2) + 1;
      cookie += LOG_BLOCK_MAX_LENGTH;
      if (newSector == cookie >> STM25P_SECTOR_SIZE_LOG2)
	cookie = (stm25p_addr_t)newSector << STM25P_SECTOR_SIZE_LOG2;

    }

    *curCookie = cookie;

    return SUCCESS;

  }

  command result_t Mount.mount[logstorage_t logId](volume_id_t id) {
    if (admitRequest(logId) == FAIL)
      return FAIL;
    state = S_MOUNT;
    return call ActualMount.mount[logId](id);
  }

  event void ActualMount.mountDone[logstorage_t logId](storage_result_t result, volume_id_t id) {

    uint8_t numSectors = call StorageManager.getNumSectors[logId]();
    uint8_t curSector;

    volumeId = id;

    curWriteBlockPos = curReadBlockLen = 0;

    // find sector with smallest/largest sector header cookie
    curWriteCookie = 0;
    curReadCookie = LOG_MAX_COOKIE;
    
    for ( curSector = 0; curSector < numSectors; curSector++ ) {
      stm25p_addr_t curAddr = curSector * STM25P_SECTOR_SIZE;
      if (call SectorStorage.read[client](curAddr, &sectorHeader, sizeof(sectorHeader))
	  == FAIL) {
	signalDone(STORAGE_FAIL);
	return;
      }

      // skip if sector header is all ones
      if (!~sectorHeader.cookie)
	continue;

      // remember smallest/largest sector header cookie
      if (sectorHeader.cookie < curReadCookie)
	curReadCookie = sectorHeader.cookie;
      if (sectorHeader.cookie > curWriteCookie)
	curWriteCookie = sectorHeader.cookie;
    }

    // advance curWriteCookie to last log block
    blockHeader.length = 0;
    do {
      curWriteCookie += blockHeader.length;
      if (advanceCookie(&curWriteCookie) == FAIL) {
 	signalDone(STORAGE_FAIL);
	return;
      }
    } while ( ~blockHeader.flags & LOG_BLOCK_ALLOCATED );

    signalDone(STORAGE_OK);
    
  }

  command result_t LogRead.read[logstorage_t logId](void* data, log_len_t numBytes) {

    log_len_t lastBytes;

    if ( admitRequest(logId) == FAIL )
      return FAIL;

    while ( numBytes > 0 ) {

      // if at beginning of block, read block header
      if ( curReadBlockLen == 0 ) {

	if (advanceCookie(&curReadCookie) == FAIL)
	  return FAIL;

	// if block header is valid
	if ( ~blockHeader.flags & LOG_BLOCK_VALID ) {
	  curReadBlockLen = blockHeader.length - sizeof(LogBlockHeader);
	  curReadCookie += sizeof(LogBlockHeader);
	}
	// if block header is for block that is currently being written
	else if ( curReadCookie >= curWriteCookie - curWriteBlockPos ) {
	  curReadBlockLen = curWriteBlockPos - sizeof(LogBlockHeader);
	  curReadCookie += sizeof(LogBlockHeader);
	}

      }

      // make sure we're not reading off the end of the log
      if (curReadCookie + numBytes > curWriteCookie)
	return FAIL;

      lastBytes = numBytes;

      // check for end of log block
      if ( curReadBlockLen < lastBytes )
	lastBytes = curReadBlockLen;

      // read data
      if (call SectorStorage.read[logId](curReadCookie, data, lastBytes) == FAIL)
	return FAIL;
      
      // advance pointers
      curReadCookie += lastBytes;
      data += lastBytes;
      curReadBlockLen -= lastBytes;
      numBytes -= lastBytes;

    }

    if (post signalDoneTask() == SUCCESS) {
      state = S_READ;
      return SUCCESS;
    }

    return FAIL;

  }

  command result_t LogRead.seek[logstorage_t logId](log_cookie_t cookie) {
    
    log_cookie_t newReadCookie;
    uint8_t numSectors = call StorageManager.getNumSectors[logId]();
    uint8_t curSector;

    if (admitRequest(logId) == FAIL)
      return FAIL;

    // look for the sector we want
    for ( curSector = 0; curSector < numSectors; curSector++ ) {
      newReadCookie = curSector * STM25P_SECTOR_SIZE;
      if (call SectorStorage.read[logId](newReadCookie, &sectorHeader, 
					 sizeof(sectorHeader)) == FAIL)
	return FAIL;
      if (newReadCookie == (cookie & ~(STM25P_SECTOR_SIZE-1)))
	break;
    }
    // couldn't find the sector we want
    if ( curSector >= numSectors )
      return FAIL;

    curReadCookie = newReadCookie;

    // scan through
    while ( curReadCookie < cookie ) {

      if (advanceCookie(&curReadCookie) == FAIL)
	return FAIL;

      // if block header is valid
      if ( ~blockHeader.flags & LOG_BLOCK_VALID )
	curReadBlockLen = blockHeader.length;
      // if block header is for block that is currently being written
      else if ( curReadCookie >= curWriteCookie - curWriteBlockPos )
	curReadBlockLen = curWriteBlockPos;

      // advance pointers
      if ( curReadCookie + curReadBlockLen > cookie ) {
	curReadBlockLen = blockHeader.length - curReadCookie;
	curReadCookie = cookie;
      }
      else {
	curReadCookie += blockHeader.length;
      }

    }
    
    if (post signalDoneTask() == SUCCESS) {
      state = S_SEEK;
      return SUCCESS;
    }

    return FAIL;
    
  }

  command result_t LogWrite.erase[logstorage_t logId]() {

    stm25p_addr_t len;

    if (admitRequest(logId) == FAIL)
      return FAIL;

    state = S_ERASE;

    len = call StorageManager.getVolumeSize[logId]();
    if (call SectorStorage.erase[logId](curWriteCookie, len) == FAIL) {
      state = S_IDLE;
      return FAIL;
    }

    return SUCCESS;

  }

  result_t appendData() {
    
    stm25p_addr_t addr;
    void* buf;
    log_len_t tmp;

    // commit log block header if at: (1) max block len or (2) end of sector
    if ( curWriteBlockPos >= LOG_BLOCK_MAX_LENGTH
	 || ( curWriteBlockPos && !(curWriteCookie % STM25P_SECTOR_SIZE) ) ) {
      blockHeader.length = curWriteBlockPos;
      blockHeader.flags = ~( LOG_BLOCK_VALID | LOG_BLOCK_ALLOCATED );
      state = S_COMMIT_BLOCK_HEADER;
      addr = curWriteCookie - curWriteBlockPos;
      buf = &blockHeader;
      lastLen = sizeof(blockHeader);
    }

    // write cookie if at start of sector
    else if ( !(curWriteCookie % STM25P_SECTOR_SIZE) ) {
      sectorHeader.cookie = curWriteCookie;
      state = S_WRITE_SECTOR_HEADER;
      addr = curWriteCookie;
      buf = &sectorHeader;
      lastLen = sizeof(sectorHeader);
    }

    // begin log block header
    else if ( !curWriteBlockPos ) {
      blockHeader.length = LOG_BLOCK_LENGTH_MASK;
      blockHeader.flags = ~( LOG_BLOCK_ALLOCATED );
      state = S_INIT_BLOCK_HEADER;
      addr = curWriteCookie;
      buf = &blockHeader;
      lastLen = sizeof(blockHeader);
    }

    // write data
    else {

      lastLen = rwLen;
      
      // check for sector boundary
      tmp = STM25P_SECTOR_SIZE - (curWriteCookie % STM25P_SECTOR_SIZE);
      if ( tmp < lastLen )
	lastLen = tmp;
      
      // check for log block boundary
      tmp = LOG_BLOCK_MAX_LENGTH - curWriteBlockPos;
      if ( tmp < lastLen )
	lastLen = tmp;
      
      state = S_APPEND;
      addr = curWriteCookie;
      buf = rwData + curLen;

    }

    return call SectorStorage.write[client](addr, buf, lastLen);

  }

  command result_t LogWrite.append[logstorage_t logId](void* data, log_len_t numBytes) {

    if (admitRequest(logId) == FAIL)
      return FAIL;

    rwData = data;
    rwLen = numBytes;
    curLen = 0;

    if (appendData() == FAIL) {
      state = S_IDLE;
      return FAIL;
    }

    return SUCCESS;

  }

  command result_t LogWrite.sync[logstorage_t logId]() {

    if (admitRequest(logId) == FAIL)
      return FAIL;

    curLen = rwLen = 0;
    blockHeader.length = curWriteBlockPos;
    blockHeader.flags = ~(LOG_BLOCK_VALID + LOG_BLOCK_ALLOCATED);
    lastLen = sizeof(blockHeader);

    state = S_SYNC;

    if (call SectorStorage.write[client](curWriteCookie-curWriteBlockPos, 
					 &blockHeader, lastLen) == FAIL) {
      state = S_IDLE;
      return FAIL;
    }

    return SUCCESS;

  }

  command log_cookie_t LogWrite.currentOffset[logstorage_t logId]() {
    return curWriteCookie;
  }

  event void SectorStorage.eraseDone[logstorage_t logId](storage_result_t result) {

    curWriteCookie = 0;
    curWriteBlockPos = 0;

    signalDone(result);

  }

  event void SectorStorage.writeDone[logstorage_t logId](storage_result_t result) { 
    
    if (state != S_COMMIT_BLOCK_HEADER && state != S_SYNC)
      curWriteCookie += lastLen;
    
    if (result != STORAGE_OK) {
      signalDone(result); 
      return;
    }

    switch(state) {
    case S_WRITE_SECTOR_HEADER: 
      break;
    case S_INIT_BLOCK_HEADER: 
      curWriteBlockPos += lastLen;
      break;
    case S_COMMIT_BLOCK_HEADER:
    case S_SYNC:
      if (curReadCookie >= curWriteCookie-curWriteBlockPos)
	curReadBlockLen = curWriteCookie-curReadCookie;
      curWriteBlockPos = 0;
      break;
    case S_APPEND: 
      curWriteBlockPos += lastLen;
      curLen += lastLen;
      break;
    }

    if (curLen >= rwLen) {
      signalDone(result);
    }
    else if (appendData() == FAIL) {
      state = S_APPEND;
      signalDone(STORAGE_FAIL);
    }
    
  }

  default event void LogRead.readDone[logstorage_t logId](storage_result_t result, void* data, log_len_t numBytes) {}
  default event void LogRead.seekDone[logstorage_t logId](storage_result_t result, log_len_t cookie) {}
  default event void LogWrite.eraseDone[logstorage_t logId](storage_result_t result) {}
  default event void LogWrite.appendDone[logstorage_t logId](storage_result_t result, void* data, log_len_t numBytes) {}
  default event void LogWrite.syncDone[logstorage_t logId](storage_result_t result) {}

  default event void Mount.mountDone[logstorage_t logId](storage_result_t result, volume_id_t id) {}

}
