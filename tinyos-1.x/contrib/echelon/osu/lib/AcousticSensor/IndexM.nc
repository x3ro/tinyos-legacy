/*
  I n d e x M . n c

  (c) Copyright 2004 The MITRE Corporation (MITRE)
*/

includes UtilSort;

module IndexM {
  provides {
    interface StdControl;
    interface Index[uint8_t inst];
  }
}

// 03/30/04 BPF Include uniqueCount of MedianIndex to work around nested
// parameterized interface problem.
implementation {
  enum {numInst = uniqueCount("MedianIndex") + uniqueCount("Index")};

  typedef uint8_t *Uint8Ptr;
  typedef Uint8Ptr Uint8ArrayRef;

  uint8_t len[numInst];
  Uint8ArrayRef data[numInst], indexToData[numInst], dataToIndex[numInst];

  /*
    StdControl interface
  */
  command result_t StdControl.init()
  {
    uint8_t i;

    for (i = 0; i < numInst; i++)
      data[i] = indexToData[i] = dataToIndex[i] = (void*) NULL;

    return SUCCESS;
  } // init

  command result_t StdControl.start()
    { return SUCCESS; }

  command result_t StdControl.stop()
    { return SUCCESS; }

  /*
    Index interface
  */
  command void Index.init[uint8_t inst]
    (uint8_t lenP,
     uint8_t *dataP, uint8_t *indexToDataP, uint8_t *dataToIndexP,
     result_t *status)
  {
    uint8_t i;

    if ((numInst < inst) || (data[inst] != NULL))
      *status = rcombine(*status,FAIL);
    else {
      data[inst] = dataP;
      indexToData[inst] = indexToDataP;
      dataToIndex[inst] = dataToIndexP;
      len[inst] = lenP;

      for (i = 0; i < len[inst]; i++) {
        data[inst][i] = 0;
        indexToData[inst][i] = dataToIndex[inst][i] = i;
      }
    }
  } // init

  command void Index.SwapIndex[uint8_t inst]
    (uint8_t indexPos0, uint8_t indexPos1, result_t *status)
  {
    if ((numInst < inst) || (data[inst] == NULL))
      *status = rcombine(*status,FAIL);
    else {
      Swap8(indexToData[inst], indexPos0,indexPos1);
      Swap8(dataToIndex[inst],
           indexToData[inst][indexPos0],indexToData[inst][indexPos1]);
    }
  } // SwapIndex

  command bool Index.OutOfOrder[uint8_t inst]
    (uint8_t indexPos0, uint8_t indexPos1, result_t *status)
  {
    bool result;
    uint8_t dataPos0,dataPos1, value0,value1;

    if ((numInst < inst) || (data[inst] == NULL)) {
      *status = rcombine(*status,FAIL);
      result = 0;
    } else {
      dataPos0 = indexToData[inst][indexPos0];
      dataPos1 = indexToData[inst][indexPos1];
      value0 = data[inst][dataPos0];
      value1 = data[inst][dataPos1];

      result = (value0 > value1);
    }

    return result;
  } // OutOfOrder
} // IndexM
