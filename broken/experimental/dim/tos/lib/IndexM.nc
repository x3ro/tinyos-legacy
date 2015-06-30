module IndexM {
  provides {
    interface StdControl;
    interface Index;
  }
  uses {
    interface StdControl as iControl;
    // interface AttrUse;
    interface quickGTS;
  }
}

/*
* Attribute registration is supposed to be done by the
* user application.
*/
implementation {
  IndexDescPtr idxDescPtr;

  command result_t StdControl.init() {
    call iControl.init();
    idxDescPtr = NULL;
    return SUCCESS;
  }

  command result_t StdControl.start() {
    call iControl.start();
    return SUCCESS;
  }

  command result_t StdControl.stop() {
    call iControl.stop();
    return SUCCESS;
  }

  /*
  * Omit input argument verification for now. The created index is
  * a DIM.
  */
  //command result_t Index.create(char *name, uint8_t attrNum, char **attrNames)
  command result_t Index.create(char *name, uint8_t tsize)
  {
    uint8_t i;
    // AttrDescPtr attrDescPtr;
    
    //dbg(DBG_USR2, "Index.create() called.\n");
    
    /*
    for (i = 0; i < MAX_INDICES; i ++) {
      if (strcasecmp(idxDesc[i].name, name) == 0 && idxDesc[i].inUse) {
        *
        * An index with the same name already exists.
        *
        dbg(DBG_USR2, "An index with the same name already exists.\n");
        return FAIL;
      }
    }
    */

    for (i = 0; i < MAX_INDICES && idxDesc[i].inUse; i ++);

    if (i == MAX_INDICES) {
      /*
      * No more indices can be created.
      */
      dbg(DBG_USR2, "No more indices can be created.\n");
      return FAIL;
    }

    atomic {
      idxDescPtr = &idxDesc[i];
      idxDescPtr->id = i;
      idxDescPtr->inUse = TRUE;
    }
    strcpy(idxDescPtr->name, name);
    /*
    * Verify that each named attribute has been registered.
    *
    /
    //idxDescPtr->fileDesc.unitSize = 0;
    //for (i = 0; i < attrNum && attrNames[i]; i ++) {
      //attrDescPtr = call AttrUse.getAttr(attrNames[i]);
      //if (attrDescPtr == NULL) {
        /*
        * Attribute not registered.
        */
        //idxDescPtr->inUse = FALSE;
        //return FAIL;
      //}
      //idxDescPtr->attrDescPtrs[i] = attrDescPtr;
      //idxDescPtr->fileDesc.tupleSize += sizeof(attrDescPtr->nbytes) + attrDescPtr->nbytes;
    //}
    idxDescPtr->fileDesc.tupleSize = tsize;
    //idxDescPtr->fileDesc.count = 0;
    /*
    * Create FS storage
    */
    if (call quickGTS.create(&(idxDescPtr->fileDesc)) == FAIL) {
      idxDescPtr->inUse = FALSE;
      dbg(DBG_USR2, "call quickGTS.create() FAILED.\n");
      return FAIL;
    }

    return SUCCESS;
  }
        
  command result_t Index.drop(char *name)
  {
    uint8_t i;
    // IndexDescPtr idxDescPtr;

    idxDescPtr = call Index.getByName(name);
    if (!idxDescPtr) {
      /*
      * Index with given name does not exist.
      */
      return FAIL;
    }
    call quickGTS.drop(&(idxDescPtr->fileDesc));
    atomic {
      idxDescPtr->inUse = FALSE;
      idxDescPtr->name[0] = '\0';
    }
    return SUCCESS;
  }

  command IndexDescPtr Index.getByName(char *name)
  {
    uint8_t i;

    for (i = 0; i < MAX_INDICES; i ++) {
      if (strcasecmp(idxDesc[i].name, name) == 0 && idxDesc[i].inUse) {
        break;
      }
    }
    if (i == MAX_INDICES) {
      return NULL;
    } 
    else {
      return &idxDesc[i];
    }
  }

  event result_t quickGTS.createDone(GTSDescPtr gp)
  {
    //dbg(DBG_USR2, "signal Index.createDone(idxDescPtr);\n");

    signal Index.createDone(idxDescPtr);
    return SUCCESS;
  }

  command result_t Index.insert(GenericTuplePtr gTuplePtr) 
  {

    //dbg(DBG_USR2, "call Index.insert()\n");
  
    if (call quickGTS.store(&(idxDescPtr->fileDesc), gTuplePtr) == FAIL) {
      return FAIL;
    }
    return SUCCESS;
  }

  event result_t quickGTS.full(GTSDescPtr gp)
  {
    signal Index.memFull();
    return SUCCESS;
  }
}

