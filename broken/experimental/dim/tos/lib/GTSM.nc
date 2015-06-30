/*-*- Mode:C++; -*-*/

/** Storage overflow check is supposed to be done by the caller **/
/** File system ready is supposed to be checked by the caller **/

module GTSM {
  provides {
    interface StdControl;
    interface GTS;
    event result_t FSysReady();
  }
  uses {
    interface FileDelete;
    interface FileRead;
    interface FileRename;
    interface FileWrite;
  }
}
implementation {
  uint8_t gState; 
  uint8_t gCapacity;
  uint8_t gRecordSize;
  uint8_t gFieldNum;
  uint8_t gRecordNum;
  uint8_t gSearchCursor;
  uint8_t gMovedRecordNum;
  uint8_t gWriteBuffer[32]; // need to revise this later
  uint8_t gReadBuffer[32]; // need to revise this later
  //char gFileName[9];
  bool gCreated;
  uint8_t gUserDefinedCursor;
  bool gFound;
  uint8_t gReadSoFar;
  //uint8_t gQueryBuffer[26];
  
  event result_t FSysReady() {
    gState = GTS_IDLE;
    return SUCCESS;
  }

  command result_t StdControl.init() {
    gState = GTS_NIL;
    gRecordSize = 0;
    gFieldNum = 0;
    gRecordNum = 0;
    gSearchCursor = 0;
    //strcpy(gFileName, "DIM");
    gCreated = FALSE;
    return SUCCESS;
  }

  command result_t StdControl.start() {
    return SUCCESS;
  }

  command result_t StdControl.stop() {
    return SUCCESS;
  }

  /*
  event result_t FSysReady() {
    gState = GTS_IDLE;
    return SUCCESS;
  }
  */
  command result_t GTS.create(uint8_t recordSize, uint8_t capacity, uint8_t fieldNum) {
    if (gState != GTS_IDLE || gCreated == TRUE || gState == GTS_ERROR) {
      return FAIL;
    } else {
      gCapacity = capacity;
      gRecordSize = recordSize;
      gFieldNum = fieldNum;
      gCreated = TRUE;
      gRecordNum = 0;
    }
    return SUCCESS;
  }

  command result_t GTS.drop()
  {
    if (!gCreated || gRecordNum == 0) {
      gCapacity = 0;
      gRecordSize = 0;
      gFieldNum = 0;
      gCreated = FALSE;
      gRecordNum = 0;
      gState = GTS_IDLE;
      return SUCCESS;
    }
#if 1
    if (gState != GTS_IDLE || gState == GTS_ERROR) {
      return FAIL;
    }
    gState = GTS_DROP;
    if (call FileDelete.delete("DIM") == FAIL) {
      gState = GTS_ERROR;
      signal GTS.broken(1);
      return FAIL;
    }
#endif
    return SUCCESS;
  }

  event result_t FileDelete.deleted(fileresult_t result) {
    if (result != FS_OK) {
      gState = GTS_ERROR;
      signal GTS.broken(1);
    } else {
      switch (gState) {
      case GTS_DROP:
        gCapacity = 0;
        gRecordSize = 0;
        gFieldNum = 0;
        gCreated = FALSE;
        gRecordNum = 0;
        gState = GTS_IDLE;
        signal GTS.dropDone();
        break;
      case GTS_STORE_DELETE:
        //signal GTS.broken(6);
#if 1
        gState = GTS_STORE_RENAME;
        if (call FileRename.rename("tmpGTS", "DIM") != SUCCESS) {
          gState = GTS_ERROR;
          signal GTS.broken(1);
        }
#endif
        break;
      default:
        break;
      }
    }
    return SUCCESS;
  }

  event result_t FileRename.renamed(fileresult_t result) {
    if (result != FS_OK) {
      gState = GTS_ERROR;
      signal GTS.broken(1);
    } else {
      switch (gState) {
        case GTS_STORE_RENAME:
          //signal GTS.broken(5);
#if 1
          gState = GTS_IDLE;
          signal GTS.storeDone();
#endif
          break;
        default:
          break;
      }
    }
    return SUCCESS;
  }

  command result_t GTS.store(void *data) {
    if (gState != GTS_IDLE || gCreated != TRUE || gState == GTS_ERROR) {
      return FAIL;
    } else {
      atomic {
        gState = GTS_STORE_OPEN_GTS_WRITE;
      }
    }

    memcpy(gWriteBuffer, data, gRecordSize);
    
    if (gRecordNum == gCapacity) {
      // Storage full
      signal GTS.full();
      /*
      * Should evict the oldest record.
      */
      gState = GTS_STORE_OPEN_TMP;
#if 1      
      if (call FileWrite.open("tmpGTS", FS_FCREATE|FS_FTRUNCATE) != SUCCESS) {
        gState = GTS_ERROR;
        signal GTS.broken(1);
        return FAIL;
      }
#endif
    }
#if 1
    else {
      if (gRecordNum == 0) {
        if (call FileWrite.open("DIM", FS_FCREATE|FS_FTRUNCATE) != SUCCESS) {
          gState = GTS_ERROR;
          signal GTS.broken(7);
          return FAIL;
        }
      } else {
        if (call FileWrite.open("DIM", 0) != SUCCESS) {
          gState = GTS_ERROR;
          signal GTS.broken(7);
          return FAIL;
        }
      }
    }
#endif
    return SUCCESS;
  }

  event result_t FileWrite.opened(filesize_t fileSize, fileresult_t result) {
    if (result != FS_OK) {
      gState = GTS_ERROR;
      signal GTS.broken(1);
    } 
    else {
#if 1
      switch (gState) {
      case GTS_STORE_OPEN_GTS_WRITE:
        gState = GTS_STORE_APPEND_GTS;
        if (call FileWrite.append(gWriteBuffer, gRecordSize) != SUCCESS) {
          gState = GTS_ERROR;
          signal GTS.broken(3);
        }
        break;
      case GTS_STORE_OPEN_TMP:
        //signal GTS.broken(5);
        gState = GTS_STORE_OPEN_GTS_READ;
        if (call FileRead.open("DIM") != SUCCESS) {
          gState = GTS_ERROR;
          signal GTS.broken(1);
        }
        break;
      default:
        break;
      }
#endif
    }
    return SUCCESS;
  }
      
  event result_t FileWrite.appended(void *buffer, filesize_t nWritten, fileresult_t result)
  {
    if (result != FS_OK || nWritten != gRecordSize) {
      gState = GTS_ERROR;
      signal GTS.broken(7);
    }
    else {
      switch (gState) {
      case GTS_STORE_APPEND_GTS:
        gRecordNum ++;
        gState = GTS_STORE_CLOSE_GTS;
        if (call FileWrite.close() != SUCCESS) {
          gState = GTS_ERROR;
          signal GTS.broken(6);
        }
        break;
      case GTS_STORE_WRITE_TMP_NEXT:
        gMovedRecordNum ++;
        //signal GTS.broken(3);
#if 1
        if (gMovedRecordNum < gRecordNum) {
          gState = GTS_STORE_READ_GTS_NEXT;
          if (call FileRead.read(gReadBuffer, gRecordSize) != SUCCESS) {
            gState = GTS_ERROR;
            signal GTS.broken(1);
          }
        } else {
          //signal GTS.broken(4);
          if (call FileRead.close() != SUCCESS) {
            gState = GTS_ERROR;
            signal GTS.broken(1);
          } else {
            //signal GTS.broken(gMovedRecordNum);
#if 1
            // Ready to append new insertion
            gState = GTS_STORE_APPEND_TMP;
            if (call FileWrite.append(gWriteBuffer, gRecordSize) != SUCCESS) {
              gState = GTS_ERROR;
              signal GTS.broken(1);
            }
#endif
          }
        }
#endif
        break;
      case GTS_STORE_APPEND_TMP:
        //signal GTS.broken(4);
#if 1
        gRecordNum ++;
        gState = GTS_STORE_CLOSE_TMP;
        if (call FileWrite.close() != SUCCESS) {
          gState = GTS_ERROR;
          signal GTS.broken(1);
        }
#endif
        break;
      default:
        break;
      }
    }
    return SUCCESS;
  }

  event result_t FileWrite.closed(fileresult_t result) {
    if (result != FS_OK) {
      gState = GTS_ERROR;
      signal GTS.broken(1);
    } else {
      switch (gState) {
      case GTS_STORE_CLOSE_TMP:
        gState = GTS_STORE_DELETE;
        //signal GTS.broken(6);
#if 1
        if (call FileDelete.delete("DIM") != SUCCESS) {
          gState = GTS_ERROR;
          signal GTS.broken(1);
        } 
#endif        
        break;
      case GTS_STORE_CLOSE_GTS:
        gState = GTS_IDLE;
        signal GTS.storeDone();
        break;
      default:
        break;
      }
    }
    return SUCCESS;
  }

  event result_t FileRead.opened(fileresult_t result) {
#if 1
    if (result != FS_OK) {
      gState = GTS_ERROR;
      signal GTS.broken(1);
    } else {
      switch (gState) {
      case GTS_STORE_OPEN_GTS_READ:
        //signal GTS.broken(5);
        if (call FileRead.read(gReadBuffer, gRecordSize) != SUCCESS) {
          gState = GTS_ERROR;
          signal GTS.broken(1);
        }
        break;
#if 0
      case GTS_GETAT_OPEN:
        gState = GTS_GETAT_READ_NEXT;
        gSearchCursor = 0;
        if (call FileRead.read(gReadBuffer, gRecordSize) != SUCCESS) {
          gState = GTS_ERROR;
          signal GTS.broken(1);
        }
        break;
#endif
      case GTS_SEARCH_OPEN:
      case GTS_SEARCH_FIRST_OPEN:
      case GTS_SEARCH_NEXT_OPEN:
        if (gState == GTS_SEARCH_OPEN) {
          gState = GTS_SEARCH_READ_NEXT;
          gSearchCursor = 0;
        } else if (gState == GTS_SEARCH_FIRST_OPEN) {
          gState = GTS_SEARCH_FIRST_READ_NEXT;
          gSearchCursor = 0;
        } else {
          gState = GTS_SEARCH_NEXT_READ_NEXT;
          gReadSoFar = 0;
        }
        if (call FileRead.read(gReadBuffer, gRecordSize) != SUCCESS) {
          gState = GTS_ERROR;
          signal GTS.broken(1);
        }
        break;
      default:
        break;
      }
    }
#endif
    return SUCCESS;
  }

  event result_t FileRead.readDone(void *buffer, filesize_t nRead, fileresult_t result)
  {
#if 1
    if (result != FS_OK || nRead != gRecordSize) {
      gState = GTS_ERROR;
      signal GTS.broken(1);
    } else {
      switch (gState) {
      case GTS_STORE_OPEN_GTS_READ:
        // We have just read the first record which should be evicted.
        //signal GTS.broken(7);
        atomic {
          gRecordNum --;
          gMovedRecordNum = 0;
          gState = GTS_STORE_READ_GTS_NEXT;
        }
        if (call FileRead.read(gReadBuffer, gRecordSize) != SUCCESS) {
          gState = GTS_ERROR;
          signal GTS.broken(1);
        }
        break;
      case GTS_STORE_READ_GTS_NEXT:
        //signal GTS.broken(4);
#if 1
        gState = GTS_STORE_WRITE_TMP_NEXT;
        if (call FileWrite.append(gReadBuffer, gRecordSize) != SUCCESS) {
          gState = GTS_ERROR;
          signal GTS.broken(1);
        }
#endif
        break;
#if 0
      case GTS_GETAT_READ_NEXT:
        if (gSearchCursor == gUserDefinedCursor) {
          if (call FileRead.close() != SUCCESS) {
            gState = GTS_ERROR;
            signal GTS.broken(1);
          } else {
            signal GTS.getAtDone(&gReadBuffer, gRecordSize);
            gState = GTS_IDLE;
          }
        } else {
          gSearchCursor ++;
          if (call FileRead.read(gReadBuffer, gRecordSize) != SUCCESS) {
            gState = GTS_ERROR;
            signal GTS.broken(1);
          }
        }
        break;
#endif
      case GTS_SEARCH_NEXT_READ_NEXT: 
        gReadSoFar ++;
        if (gReadSoFar < gSearchCursor) {
          if (call FileRead.read(gReadBuffer, gRecordSize) != SUCCESS) {
            gState = GTS_ERROR;
            signal GTS.broken(1);
          }
          break;
        } else {
          gState = GTS_SEARCH_FIRST_READ_NEXT;
        }
      case GTS_SEARCH_READ_NEXT: 
      case GTS_SEARCH_FIRST_READ_NEXT: {
        GenericTuplePtr curTup = (GenericTuplePtr)gReadBuffer;
        //GenericQueryPtr gQueryPtr = (GenericQueryPtr)gQueryBuffer;
        GenericQueryPtr gQueryPtr = (GenericQueryPtr)gWriteBuffer;
        uint8_t j;
        for (j = 0; j < gFieldNum; j ++) {
          if (curTup->value[j] < gQueryPtr->queryField[j].lowerBound || 
              curTup->value[j] >= gQueryPtr->queryField[j].upperBound) {
            break;
          }
        }
        if (j == gFieldNum) {
          // Find a matching.
          //gFound = TRUE;
          signal GTS.found(curTup);
        }
        gSearchCursor ++; // Point to the next record

//gSearchCursor = gRecordNum;
        
        if (gSearchCursor == gRecordNum) {
          if (call FileRead.close() != SUCCESS) {
            gState = GTS_ERROR;
            signal GTS.broken(1);
          } else {
            atomic {
              gState = GTS_IDLE;
            }
          }
          /*
          if (gFound == FALSE) {
            signal GTS.found(NULL);
          }
          */
          signal GTS.searchDone();
        } else {
          if (gState == GTS_SEARCH_READ_NEXT) {
            if (call FileRead.read(gReadBuffer, gRecordSize) != SUCCESS) {
              gState = GTS_ERROR;
              signal GTS.broken(1);
            }
          } else {
            if (call FileRead.close() != SUCCESS) {
              gState = GTS_ERROR;
              signal GTS.broken(1);
            } else {
              atomic {
                gState = GTS_IDLE;
              }
            }
          }
        }} break;
      default:
        break;
      }
    }
#endif
    return result;
  }

#if 0
  command result_t GTS.getAt(uint8_t idx) {
    if (gState != GTS_IDLE || gCreated != TRUE || gState == GTS_ERROR) {
      return FAIL;
    } else {
      atomic {
        gState = GTS_GETAT_OPEN;
      }
      if (call FileRead.open("DIM") != SUCCESS) {
        gState = GTS_ERROR;
        return FAIL;
      }
      gUserDefinedCursor = idx;
    }
    return SUCCESS;
  }
#endif

  event result_t FileWrite.reserved(filesize_t reservedSize, fileresult_t result) {
    return SUCCESS;
  }

  event result_t FileWrite.synced(fileresult_t result) {
    return SUCCESS;
  }

  event result_t FileRead.remaining(filesize_t n, fileresult_t result) {
    return SUCCESS;
  }

  command result_t GTS.search(GenericQueryPtr gQueryPtr) {
    if (gState != GTS_IDLE || gCreated != TRUE || gState == GTS_ERROR) {
      return FAIL;
    } else {
      atomic {
        gState = GTS_SEARCH_OPEN;
      }
      if (gRecordNum == 0) {
        // Empty storage
        signal GTS.searchDone();
        gState = GTS_IDLE;
        return SUCCESS;
      } else {
        //gFound = FALSE;
        gSearchCursor = 0;
        //memcpy(gQueryBuffer, gQueryPtr, sizeof(GenericQuery) + gFieldNum * sizeof(QueryField));
        memcpy(gWriteBuffer, gQueryPtr, sizeof(GenericQuery) + gFieldNum * sizeof(QueryField));
        if (call FileRead.open("DIM") != SUCCESS) {
          gState = GTS_ERROR;
          return FAIL;
        }
      }
    }
    return SUCCESS;
  }

  command result_t GTS.searchFirst(GenericQueryPtr gQueryPtr) {
    if (gState != GTS_IDLE || gCreated != TRUE || gState == GTS_ERROR) {
      return FAIL;
    } else {
      atomic {
        gState = GTS_SEARCH_FIRST_OPEN;
      }
      //gFound = FALSE;
      gSearchCursor = 0;
      //memcpy(gQueryBuffer, gQueryPtr, sizeof(GenericQuery) + gFieldNum * sizeof(QueryField));
      memcpy(gWriteBuffer, gQueryPtr, sizeof(GenericQuery) + gFieldNum * sizeof(QueryField));
      if (call FileRead.open("DIM") != SUCCESS) {
        gState = GTS_ERROR;
        return FAIL;
      }
    }
    return SUCCESS;
  }

  command result_t GTS.searchNext() {
    if (gSearchCursor >= gRecordNum) {
      // Have scaned the entire GTS in the last pass.
      //signal GTS.found(NULL);
      signal GTS.searchDone();
      return SUCCESS;
    }
    if (gState != GTS_IDLE || gCreated != TRUE || gState == GTS_ERROR) {
      return FAIL;
    } else {
      atomic {
        gState = GTS_SEARCH_NEXT_OPEN;
      }
      if (call FileRead.open("DIM") != SUCCESS) {
        gState = GTS_ERROR;
        return FAIL;
      }
    }
    return SUCCESS;
  }
}
