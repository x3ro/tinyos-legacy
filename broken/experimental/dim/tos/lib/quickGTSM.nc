/*-*- Mode:C++; -*-*/

/** A quick version that uses only RAM **/

module quickGTSM {
  provides {
    interface StdControl;
    interface quickGTS;
  }
  uses {
    interface MemAlloc;
  }
}
implementation {
  GTSDesc myGTS;
  Handle gHandle;
  // For automatically evict old tuples once GTS is full.
  uint8_t dataHead, dataTail;
  
  command result_t StdControl.init()
  {
    myGTS.tupleSize = 0;
    myGTS.capacity = 0;
    myGTS.fieldNum = 0;
    myGTS.data = NULL;
    dataHead = dataTail = 0;
    return SUCCESS;
  }

  command result_t StdControl.start()
  {
    return SUCCESS;
  }

  command result_t StdControl.stop()
  {
    return SUCCESS;
  }
  
  command result_t quickGTS.drop()
  {
    myGTS.tupleSize = 0;
    myGTS.capacity = 0;
    if (myGTS.data) {
      call MemAlloc.free((Handle)&(myGTS.data));
      atomic {
        myGTS.data = NULL;
      }
    } else {
      dbg(DBG_USR2, "GTS does not exist!\n");
    }
    dataHead = dataTail = 0;
      
    return SUCCESS;
  }

  command result_t quickGTS.create(uint8_t unitSize, uint8_t totalNum, uint8_t fieldNum)
  {
    myGTS.tupleSize = unitSize;
    myGTS.capacity = totalNum;
    myGTS.fieldNum = fieldNum;
    myGTS.data = NULL;
    /*
    * Allocate a big chunk of RAM.
    */
    if (call MemAlloc.allocate(&gHandle, unitSize * totalNum) == FAIL) {
      dbg(DBG_USR2, "Cannot allocate memory for GTS!\n");
      return FAIL;
    }

    return SUCCESS;
  }

  event result_t MemAlloc.allocComplete(HandlePtr handlePtr, result_t success) {
    uint8_t i;

    if (handlePtr != &gHandle) {
      return SUCCESS;
    }

    if (success != SUCCESS) {
      dbg(DBG_USR2, "Failed to allocate memory for GTS!\n");
      myGTS.tupleSize = 0;
      myGTS.capacity = 0;
    } 
    else {
      GenericTuplePtr tup;
      
      myGTS.data = (uint8_t *)(**handlePtr);
      // Use "detector" field as use/unuse tag.
      for (i = 0; i < myGTS.capacity; i ++) {
        tup = (GenericTuplePtr)&(myGTS.data[i * myGTS.tupleSize]);
        tup->detector = 0xffff;
      }
    }
    signal quickGTS.createDone(success);
    return SUCCESS;
  }
  
  /*
  * Do not need open() and close().
  */
  /*
   * Command GTS.store() appends a tuple to the data file given by 
   * *indexname*. It does not check duplicate tuples. When the storage
   * has been full, the caller is responsible to explicitly to issue
   * an eviction command and then call this command; otherwise, the
   * command will return FAIL.
   */

  /*
  * Accept only a Generic Tuple. Insert into the first free slot.
  */
  command result_t quickGTS.store(GenericTuplePtr gTuplePtr)
  {
    uint8_t i;
    GenericTuplePtr tup;
    /*
    dbg(DBG_USR2, "Insert to GTS :: %c %hd %hd %ld %ld ", 
                  i, gTuplePtr->type, gTuplePtr->queryId, gTuplePtr->sender,
                  gTuplePtr->detector, gTuplePtr->timelo, gTuplePtr->timehi);
    for (i = 0; i < myGTS.fieldNum; i ++) {
      dbg(DBG_USR2, "%hd ", gTuplePtr->value[i]);
    }
    dbg(DBG_USR2, "\n");
    */
    if (! myGTS.data) {
      // No storage allocated to store tuples.
      dbg(DBG_USR2, "GTS does not exist!\n");
      return FAIL;
    }
    else {
      if ((dataTail + 1) % myGTS.capacity == dataHead) {
        // dbg(DBG_USR2, "GTS is full! Evict the oldest tuple.\n");
        signal quickGTS.full();
        atomic {
          tup = (GenericTuplePtr)&(myGTS.data[dataHead * myGTS.tupleSize]);
          dataHead = (dataHead + 1) % myGTS.capacity;
        }
        tup->detector = 0xffff;
      }
      dbg(DBG_USR2, "Insert in GTS slot %d\n", dataTail);
      atomic {
        tup = (GenericTuplePtr)&(myGTS.data[dataTail * myGTS.tupleSize]);
        dataTail = (dataTail + 1) % myGTS.capacity;
      }
      memcpy(tup, gTuplePtr, myGTS.tupleSize);
      /*
      for (i = 0; i < myGTS.fieldNum; i ++) {
        tup->value[i] = gTuplePtr->value[i];
      }
      */
      dbg(DBG_USR2, "Insert to GTS :: %c %hd %hd %ld %ld ", 
                    tup->type, tup->queryId, tup->sender,
                    tup->detector, tup->timelo, tup->timehi);
      for (i = 0; i < myGTS.fieldNum; i ++) {
        dbg(DBG_USR2, "%hd ", tup->value[i]);
      }
      dbg(DBG_USR2, "\n");
      return SUCCESS;
    }
  }
  
  /*
  * Search for a match to the given query.
  */
  command result_t quickGTS.search(GenericQueryPtr gQueryPtr)
  {
    bool found = FALSE;
    uint8_t i, j;
    GenericTuplePtr curTup;

    if (! myGTS.data) {
      // No storage allocated to store tuples.
      dbg(DBG_USR2, "GTS does not exist!\n");
      return FAIL;
    }
    if (dataHead == dataTail) {
      // Storage is empty.
      signal quickGTS.found(NULL);
      return SUCCESS;
    }

    i = dataHead;
    do {
      curTup = (GenericTuplePtr)&(myGTS.data[i * myGTS.tupleSize]);
      for (j = 0; j < myGTS.fieldNum; j ++) {
        if (curTup->value[j] < gQueryPtr->queryField[j].lowerBound || 
            curTup->value[j] >= gQueryPtr->queryField[j].upperBound) {
          break;
        }
      }
      if (j == myGTS.fieldNum) {
        // Find a matching.
        uint8_t k;
        
        dbg(DBG_USR2, "Found a match at slot %d :: %c %hd %hd %ld %ld ", 
                      i, curTup->type, curTup->queryId, curTup->sender,
                      curTup->detector, curTup->timelo, curTup->timehi);
        for (k = 0; k < myGTS.fieldNum; k ++) {
          dbg(DBG_USR2, "%hd ", curTup->value[k]);
        }
        dbg(DBG_USR2, "\n");
        
        found = TRUE;
        signal quickGTS.found(curTup);
      }
      i = (i + 1) % myGTS.capacity;
    } while (i != dataTail);
                    
    if (! found) {
      dbg(DBG_USR2, "No match found!\n");
      signal quickGTS.found(NULL);
    }
    return SUCCESS;
  }

  /*
  * Delete tuples whose timestamp is older than the given one.
  */
  /*
  command result_t quickGTS.delete(uint32_t timeLo, uint32_t timeHi)
  {
    uint8_t i;

    if (! myGTS.data) {
      // No storage allocated to store tuples
      dbg(DBG_USR2, "GTS does not exist!\n");
      return FAIL;
    }
    for (i = 0; i < myGTS.capacity; i ++) {
      if (myGTS.data[i].timehi < timeHi || 
          (myGTS.data[i].timehi == timeHi && myGTS.data[i].timelo < timeLo)) {
        myGTS.data[i].moteId = 0xffff;
      }
    }
    return SUCCESS;
  }
  */
  command result_t quickGTS.delete(uint32_t timeLo, uint32_t timeHi)
  {
    uint8_t i, j, k;
    GenericTuplePtr curTup, tup, tup1;

    if (! myGTS.data) {
      // No storage allocated to store tuples
      dbg(DBG_USR2, "GTS does not exist!\n");
      return FAIL;
    }
    for (i = dataHead; ((i + 1) % myGTS.capacity) != dataTail; i = (i + 1) % myGTS.capacity) {
      curTup = (GenericTuplePtr)&(myGTS.data[i * (sizeof(GenericTuple) + myGTS.tupleSize)]);
      if (curTup->timehi < timeHi || 
          (curTup->timehi == timeHi && curTup->timelo < timeLo)) {
        // myGTS.data[i].moteId = 0xffff;
        // Move forward to cover the idle slot.
        for (j = (i + 1) % myGTS.capacity; ((j + 1) % myGTS.capacity) !=  dataTail; j = (j + 1) % myGTS.capacity) {
          //myGTS.data[(j - 1 + myGTS.capacity) % myGTS.capacity] = myGTS.data[j];
          tup = (GenericTuplePtr)&(myGTS.data[((j - 1 + myGTS.capacity) % myGTS.capacity) * (sizeof(GenericTuple) + myGTS.tupleSize)]);
          tup1 = (GenericTuplePtr)&(myGTS.data[j * (sizeof(GenericTuple) + myGTS.tupleSize)]);
          *tup = *tup1;
          for (k = 0; k < myGTS.fieldNum; k ++) {
            tup->value[k] = tup1->value[k];
          }
        }
      }
    }
    
    return SUCCESS;
  }

  event result_t MemAlloc.reallocComplete(Handle handle, result_t success) {
    return SUCCESS;
  }

  event result_t MemAlloc.compactComplete() {
    return SUCCESS;
  }
}
