includes BlockStorage;
includes FSMate;

module FlashLoggerM {
  provides {
    interface LogWrite;
    interface LogRead;
    interface VolumeInit;
  }
  uses {
    interface BlockWrite;
    interface BlockRead;
    interface Mount;
    interface FormatStorage;
    interface InternalFlash as IFlash;

    interface SplitControl as RadioControl;
    interface Leds;
  }
}

implementation {
  uint8_t* writePtr;
  uint32_t writeBytes;
  uint8_t* readPtr;
  uint32_t readBytes;
  // file metadata cache... backed in InternalFlash
  uint32_t curWOffset;
  uint32_t curROffset;
  uint32_t flashZero = 0;
  uint8_t freshStart;

  /* 
   * The following 3 functions are used to simulate split-phaseness. See
   * NesC documentation for details on how this works.
   */
  task void RseekDone() {
    signal LogRead.seekDone(STORAGE_OK, curROffset);
  }
  task void VinitDone() {
    signal VolumeInit.initDone(STORAGE_OK);
  }
  task void WsyncDone() {
    signal LogWrite.syncDone(STORAGE_OK);
  }

  /*
   * This is a somewhat complicated piece of code. When the mote powers on,
   * we want to know if the flash has already been initialized. We do this
   * by checking for a magic cookie (0xAB). If we find it, then we just
   * mount the blocks and continue with bootup. If we don't find it, we need
   * to format and allocate a chunk of flash. See TinyOS 2.x TEP103 for more
   * details on the bootup process. Red LEDs will turn on if at any point
   * the file system could not be started properly. See README for other
   * details on Configurables.
   */
  // WARNING: Wait for radio to load before starting flash, having the
  //   flash and radio race for the bus will cause severe problems
  event result_t RadioControl.startDone() {
    result_t rval;
    call IFlash.read((void*)LOC_STARTCOOKIE, (void*)&freshStart, 1);
    if(freshStart != 0xAB) { // 0xAB is a magic cookie
      call Leds.set(4);
      // Will this break Deluge?
      rval = call FormatStorage.init();
      if(rval != SUCCESS) {
	call Leds.set(1);
	return SUCCESS;
      }
      rval = call FormatStorage.allocate(FSMATE_VOL_ID,
					 (storage_addr_t)STORAGE_BLOCK_SIZE*(storage_addr_t)FSMATE_NUM_BLOCKS);
      if(rval != SUCCESS) {
	call Leds.set(1);
	return SUCCESS;
      }
      rval = call FormatStorage.commit();
      if(rval != SUCCESS) {
	call Leds.set(1);
	return SUCCESS;
      }
      // WARNING: This technically needs to be done in commitDone, but
      //   it may not be getting signalled in some builds.

      // freshStart = 0xAB;
      // call IFlash.write((void*)12, (void*)&freshStart, 1);
    } else {
      // mount file system if already initialized
      rval = call Mount.mount(FSMATE_VOL_ID);
      if(rval != SUCCESS) {
	call Leds.set(1);
	return SUCCESS;
      }
    }
    return SUCCESS;
  }

  /*
   * This loads necessary metadata of the flash system. More specifically,
   * we'd like to know the last place we should start appending data if the
   * power is lost at any point. See README for InternalFlash layout.
   */
  command result_t VolumeInit.init() {
    // read contents from internal flash memory;
    result_t rval;
    rval = call IFlash.read((void*)LOC_BLKOFFSET, (void*)&curWOffset, 4);
    // do some handling for clean re-programs
    if(curWOffset == -1) {
      curWOffset = 0;
    }
    // initialize values
    curROffset = 0;
    post VinitDone();
    return rval;
  }

  /*
   * After we format the storage, we want to make sure it was properly saved.
   * If it is, we need to write our magic cookie (0xAB) so that the flash
   * isn't formatted again. Then we mount the flash.
   */
  event void FormatStorage.commitDone(storage_result_t result) {
    result_t rval;
    if (result != STORAGE_OK) {
      call Leds.set(1);
      return;
    }
    // set magic cookie so we don't keep initializing
    freshStart = 0xAB;
    call IFlash.write((void*)LOC_STARTCOOKIE, (void*)&freshStart, 1);
    // mount file system
    rval = call Mount.mount(FSMATE_VOL_ID);
    if(rval != SUCCESS) {
      call Leds.set(1);
      return;
    }
  }

  /*
   * When the flash has been mounted, we want to continue with the rest of
   * the initialization. Specifically we want to load any metadata.
   */
  event void Mount.mountDone(storage_result_t result, uint8_t id) {
    // initialize the DataCache component
    if(result == STORAGE_OK) {
      call VolumeInit.init();
      return;
    }
    call Leds.set(1);
  }

  /*
   * During an erase, we erase the flash as well as reset the address we
   * want to write to. This is done by zeroing the metadata as well as
   * in memory variables.
   */
  command result_t LogWrite.erase() {
    result_t rval;
    // erase the cookies
    rval = call IFlash.write((void*)LOC_BLKOFFSET, (void*)&flashZero, 4);
    rval &= call BlockWrite.erase();
    // initialize the Flash metadata
    curWOffset = 0;
    curROffset = 0;
    return rval;
  }

  /* Complete the split-phaseness of erasing with a signal */
  event void BlockWrite.eraseDone(storage_result_t result) {
    if(result == STORAGE_OK) {
      signal LogWrite.eraseDone(STORAGE_OK);
    } else {
      signal LogWrite.eraseDone(STORAGE_FAIL);
    }    
  }

  /*
   * Check to make sure we have enough space to actually completely write
   * our data. If so, use the underlying BlockWrite interface (as specified
   * in TinyOS 2.x TEP103) and save pointer and size information.
   */
  command result_t LogWrite.append(void* data, log_len_t numBytes) {
    // check if you're just out of disk space
    if(curWOffset < 0 || curWOffset > (storage_addr_t)STORAGE_BLOCK_SIZE*(storage_addr_t)FSMATE_NUM_BLOCKS) {
      return FAIL;
    }
    if(call BlockWrite.write((block_addr_t)curWOffset,
			     data,
			     (block_addr_t) numBytes)
       == FAIL) {
      return FAIL;
    }
    writePtr = data;
    writeBytes = numBytes;
    return SUCCESS;
  }

  /*
   * After a write is complete, update the current write pointer in both
   * memory and flash. Then signal the result to FSMate.
   */
  event void BlockWrite.writeDone(storage_result_t sresult,
				  block_addr_t addr,
				  void* buf,
				  block_addr_t len) {
    result_t rval;
    // do we really know all the bytes got written?
    // are there partial writes?
    curWOffset += writeBytes;
    rval = call IFlash.write((void*)LOC_BLKOFFSET, (void*)&curWOffset, 4);
    if((sresult == STORAGE_OK) && (rval == SUCCESS)) {
      signal LogWrite.appendDone(STORAGE_OK, writePtr, writeBytes);
    } else {
      signal LogWrite.appendDone(STORAGE_FAIL, writePtr, writeBytes);      
    }
  }

  command log_cookie_t LogWrite.currentOffset() {
    return curWOffset;
  }

  /*
   * If we had memory buffering for the flash, we'd actually need to
   * commit it, but there is none right now, so we just post a task that
   * signals DONE, to fake it.
   */
  command result_t LogWrite.sync() {
    post WsyncDone();
    return SUCCESS;
  }

  // this is just here to satisfy compiler, BlockStorage doesn't have
  //   buffering at the moment.
  event void BlockWrite.commitDone(storage_result_t result) {
    return;
  }

  /*
   * Try to read the data, and save the pointer and size information
   */
  command result_t LogRead.read(void* data, uint32_t numBytes) {
    if(call BlockRead.read(curROffset,
			   data,
			   (block_addr_t) numBytes) ==
       FAIL) {
      return FAIL;
    }
    readPtr = data;
    readBytes = numBytes;    
    return SUCCESS;
  }

  /*
   * Update the in-memory read offset, but don't worry about flash. It's
   * not critically important to waste flash access. Then signal
   * completion.
   */
  event void BlockRead.readDone(storage_result_t sresult,
				block_addr_t addr,
				void* buf,
				block_addr_t len) {
    // do we really know all the bytes got read?
    // are there partial reads?
    curROffset += readBytes;
    signal LogRead.readDone(STORAGE_OK, readPtr, readBytes);
  }

  /*
   * Seek the reading part of the file pointer
   */
  command result_t LogRead.seek(uint32_t cookie) {
    // If you seek off the file, you'll just get garbage
    curROffset = cookie;
    post RseekDone();
    return SUCCESS;
  }

  /*
   * The rest of the functions are used to satisfy the NesC compiler.
   */
  event void BlockRead.verifyDone(result_t result) {
    return;
  }
  event void BlockRead.computeCrcDone(storage_result_t result, uint16_t crc, block_addr_t addr, block_addr_t len) {
    return;
  }

  event result_t RadioControl.initDone() { return SUCCESS; }
  event result_t RadioControl.stopDone() { return SUCCESS; }
}
