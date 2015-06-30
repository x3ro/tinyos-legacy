
/**
 * DelugeMetadataM.nc - Manages metadata.
 *
 * @author Jonathan Hui <jwhui@cs.berkeley.edu>
 * @since  0.1
 */

module DelugeMetadataM {
  provides {
    interface StdControl;
    interface DelugeMetadata as Metadata;
  }
  uses {
    interface BitVecUtils;
    interface DelugeMetadataStableStore as StableStore;
    interface StdControl as StableStoreControl;
  }
}
implementation {

  // metadata for img on flash
  DelugeMetadata metadata;

  // state of metadata component
  uint8_t state;
  uint8_t pageAgesToUpdate[DELUGE_PAGE_BITVEC_SIZE];

  enum {
    S_IDLE,
    S_FLUSHING,
    S_FLUSHING_PAGEDIFF,
  };

  command result_t StdControl.init() {

    // init data structures
    metadata.summary.vNum = 0;
    metadata.numPgs = 0;
    memset(metadata.deltas, 0x0, DELUGE_DELTA_VEC_SIZE);
    memset(metadata.incompletePgs, 0x0, DELUGE_PAGE_BITVEC_SIZE);

    // init state
    state = S_IDLE;

    return call StableStoreControl.init();

  }

  command result_t StdControl.start() {
    if (!call StableStoreControl.start())
      return FAIL;
    return call StableStore.getMetadata(&metadata);
  }
  command result_t StdControl.stop() {
    return call StableStoreControl.stop();
  }

  command imgvnum_t Metadata.getVNum() { return metadata.summary.vNum; }
  command imgvnum_t Metadata.getPrevVNum() { return metadata.prevVNum; }
  command uint16_t Metadata.getNumPgs() { return metadata.numPgs; }
  command uint16_t Metadata.getNumPgsComplete() { return metadata.summary.numPgsComplete; }
  command uint32_t Metadata.getImgSize() { return metadata.imgSize; }
  command bool Metadata.isNewer(DelugeImgSummary* summary) { return (summary->vNum > metadata.summary.vNum); }
  command bool Metadata.isUpdating() { return (metadata.summary.vNum != metadata.prevVNum); }

  // every time you flush page this is called
  // flush meta data when all pages are completed
  command result_t Metadata.pgFlushed(uint16_t pgNum) {

    uint16_t numPgsComplete;

    if (state != S_IDLE)
      return FAIL;

    BITVEC_CLEAR(metadata.incompletePgs, pgNum);
    if (call BitVecUtils.indexOf(&numPgsComplete, 0, metadata.incompletePgs, 
				 metadata.numPgs)) {
      // now have more pages complete
      metadata.summary.numPgsComplete = numPgsComplete;
    }
    else {
      // entire image is complete
      metadata.summary.numPgsComplete = metadata.numPgs;
      // flush metadata to stable store
      state = S_FLUSHING;
      call StableStore.writeMetadata(&metadata);
    }

    return SUCCESS;

  }
  
  command result_t Metadata.getImgSummary(DelugeImgSummary* pResult) {
    *pResult = metadata.summary;
    return SUCCESS;
  }

  command result_t Metadata.getNextIncompletePage(uint16_t* pResult) {

    if (call BitVecUtils.indexOf(pResult, 0, metadata.incompletePgs, 
				 metadata.numPgs)) {
      return SUCCESS;
    }
    
    return FAIL;

  }

  command result_t Metadata.generatePageDiff(DelugeImgDiff* pResult,
					     imgvnum_t oldVNum, uint8_t pktNum) {
    int i;
    
    if (metadata.summary.vNum <= oldVNum
	|| metadata.summary.vNum != metadata.prevVNum)
      return FAIL;

    pResult->vNum = metadata.summary.vNum;
    pResult->imgSize = metadata.imgSize;

    if (metadata.summary.vNum == oldVNum + 1) {
      // versions differs by one, just send bitvec
      pResult->startPg = (uint16_t)pktNum * 8 * DELUGE_DIFF_PKT_BITVEC_SIZE;
      if (pResult->startPg >= metadata.numPgs) {
	return FAIL;
      }
      pResult->type = DELUGE_DIFF;
      memset(pResult->updateVector, 0x0, DELUGE_PAGE_BITVEC_SIZE);
      for ( i = 0; (pResult->startPg+i < metadata.numPgs) && (i < 8*DELUGE_DIFF_PKT_BITVEC_SIZE); i++ ) {
	if (NIBBLEVEC_GET(metadata.deltas, pResult->startPg + i) == 0)
	  BITVEC_SET(pResult->updateVector, i);
      }
    }
    else {
      // versions differ by more than one, have to send all deltas
      pResult->startPg = pktNum * DELUGE_NUM_DELTAS_PER_PKT;
      if (pResult->startPg >= metadata.numPgs)
	return FAIL;
      pResult->type = DELUGE_DELTAS;
      for ( i = 0; (pResult->startPg+i < metadata.numPgs) && (i < DELUGE_NUM_DELTAS_PER_PKT); i++ ) {
	NIBBLEVEC_SET(pResult->updateVector, i,
		      NIBBLEVEC_GET(metadata.deltas, pResult->startPg + i));
      }
    }

    return SUCCESS;

  }

  task void syncMetadata() {
    if (!call StableStore.writeMetadata(&metadata))
      post syncMetadata();
  }

  command result_t Metadata.applyPageDiff(DelugeImgDiff* pDiff) {

    uint16_t result;
    uint16_t vNumDiff;
    int i;
    
    if ((state != S_IDLE)
	|| (pDiff->vNum < metadata.summary.vNum)
	|| (pDiff->vNum == metadata.summary.vNum 
	    && metadata.summary.vNum == metadata.prevVNum))
      return FAIL;
    
    if (pDiff->vNum != metadata.summary.vNum) {
      // first metadata update packet of new version, get ready!
      vNumDiff = pDiff->vNum - metadata.summary.vNum;
      for ( i = 0; i < metadata.numPgs; i++ ) {
	if (NIBBLEVEC_GET(metadata.deltas, i) + vNumDiff < UINT4_MAX)
	  NIBBLEVEC_SET(metadata.deltas, i,
			NIBBLEVEC_GET(metadata.deltas, i) + vNumDiff);
	else
	  NIBBLEVEC_SET(metadata.deltas, i, UINT4_MAX);
      }
      metadata.summary.vNum = pDiff->vNum;
      metadata.summary.numPgsComplete = 0;
      metadata.imgSize = pDiff->imgSize;
      metadata.numPgs = ((pDiff->imgSize-1)/DELUGE_BYTES_PER_PAGE)+1;

      // XXX: HACK!!!!!
      memset(pageAgesToUpdate, 0x00, DELUGE_PAGE_BITVEC_SIZE);
      memset(metadata.incompletePgs, 0xff, DELUGE_PAGE_BITVEC_SIZE);
    }
    
    if (pDiff->type == DELUGE_DIFF
	&& pDiff->vNum == metadata.prevVNum+1) {
      // versions differ by one, just use bitvec
      for ( i = 0; (pDiff->startPg+i < metadata.numPgs) && (i < 8*DELUGE_DIFF_PKT_BITVEC_SIZE); i++ ) {
	if (BITVEC_GET(pDiff->updateVector,i)) {
	  NIBBLEVEC_SET(metadata.deltas, pDiff->startPg+i, 0x0);
	  BITVEC_SET(metadata.incompletePgs,pDiff->startPg+i);
	}
	BITVEC_CLEAR(pageAgesToUpdate, pDiff->startPg+i);
      }
    }
    else if (pDiff->type == DELUGE_DELTAS) {
      // versions differ by more than one, process each delta
      for ( i = 0; (pDiff->startPg+i < metadata.numPgs) && (i < DELUGE_NUM_DELTAS_PER_PKT); i++ ) {
	if (NIBBLEVEC_GET(pDiff->updateVector, i) < 
	    NIBBLEVEC_GET(metadata.deltas, pDiff->startPg + i)) {
	  // this page has changed, need to get it
	  BITVEC_SET(metadata.incompletePgs, i);
	}
	NIBBLEVEC_SET(metadata.deltas, pDiff->startPg + i,
		      NIBBLEVEC_GET(pDiff->updateVector, i));
	BITVEC_CLEAR(pageAgesToUpdate, pDiff->startPg+i);
      }
    }
    
    if (call BitVecUtils.indexOf(&result, 0, pageAgesToUpdate, metadata.numPgs)
	== FAIL) {
      if (metadata.prevVNum != metadata.summary.vNum) {
	// all done with updates to metadata
	metadata.prevVNum = metadata.summary.vNum;
	if (call BitVecUtils.indexOf(&result, 0, metadata.incompletePgs, metadata.numPgs))
	  metadata.summary.numPgsComplete = result;
	else
	  metadata.summary.numPgsComplete = metadata.numPgs;
	
	// flush metadata to stable store
	state = S_FLUSHING_PAGEDIFF;
	post syncMetadata();
      }
    }

    return SUCCESS;

  }

  event result_t StableStore.getMetadataDone(result_t result) {
    if (metadata.sig != 0xdead) {
      // metadata not valid, throw out
      metadata.summary.vNum = 0;
      metadata.summary.numPgsComplete = 0;
      metadata.sig = 0xdead;
      metadata.imgSize = 0;
      metadata.numPgs = 0;
      metadata.prevVNum = 0;
      memset(metadata.deltas, 0x0, DELUGE_DELTA_VEC_SIZE);
      memset(metadata.incompletePgs, 0x0, DELUGE_PAGE_BITVEC_SIZE);
    }
    return signal Metadata.ready(result);
  }

  event result_t StableStore.writeMetadataDone(result_t result) {
    switch(state) {
    case S_FLUSHING_PAGEDIFF:
      state = S_IDLE;
      return signal Metadata.applyPageDiffDone(result);
    case S_FLUSHING:
      state = S_IDLE;
    }

    return SUCCESS;
  }

}
