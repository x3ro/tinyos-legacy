
/**
 * DelugeStableStoreM.nc - Provides stable storage services to Deluge.
 *
 * @author Jonathan Hui <jwhui@cs.berkeley.edu>
 * @since  0.1
 */

module DelugeStableStoreM {
  provides {
    interface StdControl;
    interface DelugeImgStableStore as ImgStableStore;
    interface DelugeMetadataStableStore as MetadataStableStore;
  }
  uses {
    interface PageEEPROM as Flash;
    interface StdControl as FlashControl;
    interface BootImg;
  }
}

implementation {

  enum {
    S_IDLE,
    S_READ_METADATA,
    S_READ_DATA,
    S_WRITE_METADATA,
    S_WRITE_DATA,
  };

  uint8_t state;
  eeprompage_t writePageNum;

  command result_t StdControl.init() { 
    return SUCCESS; 
  }
  command result_t StdControl.start() {
    state = S_IDLE;
    return SUCCESS;
  }
  command result_t StdControl.stop() { 
    return SUCCESS; 
  }

  command result_t MetadataStableStore.getMetadata(DelugeMetadata* metadata) {

    if (state != S_IDLE)
      return FAIL;
    
    state = S_READ_METADATA;

#ifdef PLATFORM_PC
    metadata->numPgs = 1;
    metadata->summary.vNum = 0;
    metadata->summary.numPgsComplete = 1;
    metadata->imgSize = 512;
    if (TOS_LOCAL_ADDRESS == 0) {
      metadata->summary.vNum = 1;
    }
    metadata->prevVNum = metadata->summary.vNum;
    state = S_IDLE;
    return signal MetadataStableStore.getMetadataDone(SUCCESS);
#endif

    return call Flash.read(DELUGE_FLASH_METADATA_PAGE, 0x0,
			   metadata, sizeof(DelugeMetadata));

  }

  event result_t Flash.readDone(result_t result) { 

    if (result == FAIL) {
      // read failed, give up
      state = S_IDLE;
      return signal MetadataStableStore.getMetadataDone(result);
    }
    
    state = S_IDLE;
    return signal MetadataStableStore.getMetadataDone(result);

  }

  command result_t ImgStableStore.setImgAttributes(uint16_t pid, uint32_t imgSize) {
    return call BootImg.setImgAttributes(pid, imgSize);
  }

  command result_t ImgStableStore.getImgData(uint32_t offset, uint8_t* dest,
					     uint32_t length) {
    
    if (state != S_IDLE)
      return FAIL;
    
    state = S_READ_DATA;
    
    return call BootImg.read(dest, offset, length);
    
  }

  event result_t BootImg.readDone(result_t result) {

    state = S_IDLE;
    return signal ImgStableStore.getImgDataDone(result);

  }

  command result_t MetadataStableStore.writeMetadata(DelugeMetadata* metadata) {

    if (state != S_IDLE)
      return FAIL;

    state = S_WRITE_METADATA;

    writePageNum = DELUGE_FLASH_METADATA_PAGE;
    return call Flash.write(writePageNum, 0, metadata, sizeof(DelugeMetadata));

  }

  event result_t Flash.writeDone(result_t result) {

    if (result == FAIL) {
      // write failed, give up
      state = S_IDLE;
      return signal MetadataStableStore.writeMetadataDone(result);
    }

    // sync flash buffer
    return call Flash.sync(writePageNum);

  }

  event result_t Flash.syncDone(result_t result) { 
    
    if (result == FAIL) {
      // write failed, give up
      state = S_IDLE;
      return signal MetadataStableStore.writeMetadataDone(result);
    }
    
    state = S_IDLE;
    return signal MetadataStableStore.writeMetadataDone(result);
    
  }

  command result_t ImgStableStore.writeImgData(uint32_t offset, uint8_t* source, 
					       uint32_t length) {

    if (state != S_IDLE)
      return FAIL;

    state = S_WRITE_DATA;

    return call BootImg.write(source, offset, length);

  }

  event result_t BootImg.writeDone(result_t result) {

    if (result == FAIL) {
      state = S_IDLE;
      return signal ImgStableStore.writeImgDataDone(result);
    }

    return call BootImg.sync();

  }

  event result_t BootImg.syncDone(result_t result) {

    state = S_IDLE;
    return signal ImgStableStore.writeImgDataDone(result);

  }

  event result_t Flash.flushDone(result_t result) { return SUCCESS; }
  event result_t Flash.eraseDone(result_t result) { return SUCCESS; }
  event result_t Flash.computeCrcDone(result_t result, uint16_t crc) { return SUCCESS; }

}
