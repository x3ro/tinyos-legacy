/*
  M e d i a n I n d e x M . n c

  (c) Copyright 2004 The MITRE Corporation (MITRE)

   Permission is hereby granted, without payment, to copy, use, modify,
   display and distribute this software and its documentation, if any,
   for any purpose, provided, first, that the US Government and any of
   its agencies will not be charged any license fee and/or royalties for
   the use of or access to said copyright software, and provided further
   that the above copyright notice and the following three paragraphs
   shall appear in all copies of this software, including derivatives
   utilizing any portion of the copyright software.  Use of this software
   constitutes acceptance of these terms and conditions.

   IN NO EVENT SHALL MITRE BE LIABLE TO ANY PARTY FOR DIRECT, INDIRECT,
   SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE
   OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF MITRE HAS BEEN ADVISED
   OF THE POSSIBILITY OF SUCH DAMAGE.

   MITRE SPECIFICALLY DISCLAIMS ANY EXPRESS OR IMPLIED WARRANTIES
   INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
   MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, AND
   NON-INFRINGEMENT.

   THE SOFTWARE IS PROVIDED "AS IS."  MITRE HAS NO OBLIGATION TO PROVIDE
   MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS.

*/

includes UtilMath;

module MedianIndexM {
  provides {
    interface StdControl;
    interface MedianIndex[uint8_t inst];
  }

  uses interface Index[uint8_t inst];
}

implementation {
  enum {numInst = uniqueCount("MedianIndex")};

  typedef uint8_t *Uint8Ptr;
  typedef Uint8Ptr Uint8ArrayRef;

  uint8_t len[numInst];
  Uint8ArrayRef dataToIndex[numInst], indexToData[numInst], data[numInst];

  /*
    Helper functions
  */

  inline uint8_t Parent(uint8_t i)
    { return ((i + 1) >> 1) - 1; }

  inline uint16_t FirstChild(uint8_t i)
    { return ((((uint16_t)i) + 1) << 1) - 1; }

  //inline bool IsOdd(uint8_t num)
  //  { return (num & 1); }

  /*
    Movement funcitons
  */
  uint8_t MoveUp(uint8_t inst, uint8_t indexPos)
  {
    uint16_t upIndex0, upIndex1;
    uint8_t upIndex, newIndexPos, minUpper, maxLower;
    bool outOfOrder0, outOfOrder1;
    result_t status;
    
    status = SUCCESS;
    minUpper = (len[inst] >> 1);
    maxLower = ((len[inst] - 1) >> 1);

    if (indexPos < minUpper) {
      if (indexPos == maxLower)
        upIndex = indexPos + 1;
      else
        upIndex = maxLower - Parent(maxLower - indexPos);

      if (call Index.OutOfOrder[inst](indexPos, upIndex, &status)) {
        call Index.SwapIndex[inst](indexPos,upIndex, &status);
        newIndexPos = upIndex;
      } else
        newIndexPos = indexPos;

    } else { // (minUppper <= indexPos)
      upIndex0 = FirstChild(indexPos - minUpper) + minUpper;
      upIndex1 = upIndex0 + 1;

      outOfOrder0 =
        ((upIndex0 < len[inst]) &&
         call Index.OutOfOrder[inst](indexPos, upIndex0,&status));
      outOfOrder1 =
        ((upIndex1 < len[inst]) &&
         call Index.OutOfOrder[inst](indexPos, upIndex1,&status));

      if ( outOfOrder0 && outOfOrder1 ) {
        upIndex =
          call Index.OutOfOrder[inst](upIndex0,upIndex1, &status) ?
            upIndex1 : upIndex0;
        call Index.SwapIndex[inst](indexPos,upIndex, &status);
        newIndexPos = upIndex;

      } else if ( outOfOrder0 ) {
        call Index.SwapIndex[inst](indexPos,upIndex0, &status);
        newIndexPos = upIndex0;

      } else if ( outOfOrder1 ) {
        call Index.SwapIndex[inst](indexPos,upIndex1, &status);
        newIndexPos = upIndex1;

      } else
        newIndexPos = indexPos;
    }

    return newIndexPos;
  } // MoveUp

  uint8_t MoveDown(uint8_t inst, uint8_t indexPos)
  {
    int16_t downIndex0, downIndex1;
    uint8_t downIndex, newIndexPos, minUpper, maxLower;
    bool outOfOrder0, outOfOrder1;
    result_t status;

    status = SUCCESS;
    minUpper = (len[inst] >> 1);
    maxLower = ((len[inst] - 1) >> 1);

    if (maxLower < indexPos) {
      if (indexPos == minUpper)
        downIndex = indexPos - 1;
      else
        downIndex = Parent(indexPos - minUpper) + minUpper;
      
      if (call Index.OutOfOrder[inst](downIndex,indexPos, &status)) {
        call Index.SwapIndex[inst](downIndex,indexPos, &status);
        newIndexPos = downIndex;
      } else
        newIndexPos = indexPos;

    } else { // (indexPos <= maxLower)
      downIndex0 = maxLower - FirstChild(maxLower - indexPos);
      downIndex1 = downIndex0 - 1;

      outOfOrder0 =
        ((0 <= downIndex0) &&
         call Index.OutOfOrder[inst](downIndex0,indexPos, &status));
      outOfOrder1 =
        ((0 <= downIndex1) &&
         call Index.OutOfOrder[inst](downIndex1,indexPos, &status));

      if ( outOfOrder0 && outOfOrder1 ) {
        downIndex =
          call Index.OutOfOrder[inst](downIndex0,downIndex1, &status) ?
            downIndex0 : downIndex1;
        call Index.SwapIndex[inst](indexPos,downIndex, &status);
        newIndexPos = downIndex;

      } else if ( outOfOrder0 ) {
        call Index.SwapIndex[inst](indexPos,downIndex0, &status);
        newIndexPos = downIndex0;

      } else if ( outOfOrder1 ) {
        call Index.SwapIndex[inst](indexPos,downIndex1, &status);
        newIndexPos = downIndex1;

      } else
        newIndexPos = indexPos;
    }

    return newIndexPos;
  } // MoveDown


  /*
    Standard control
  */
  command result_t StdControl.init()
  {
    /*
    uint8_t i;
    
    for (i = 0; i < (int)numInst; i++)
      data[i] = dataToIndex[i] = indexToData[i] = NULL;
    */
    
    return SUCCESS;
  } // init

  command result_t StdControl.start()
  {  
    return SUCCESS;
  } // init

  command result_t StdControl.stop()
  {
    return SUCCESS;
  } // init

  /*
    Main interface
  */
  command void MedianIndex.start[uint8_t inst]
    (uint8_t lenArg,
     uint8_t *dataArg, uint8_t *indexToDataArg, uint8_t *dataToIndexArg,
     result_t *status)
  {

    if ((numInst <= inst)||(data[inst]!=NULL))
      *status = rcombine(*status,FAIL);
    else {
      data[inst] = dataArg;
      indexToData[inst] = indexToDataArg;
      dataToIndex[inst] = dataToIndexArg;
      len[inst] = lenArg;

      call Index.init[inst](lenArg, dataArg,indexToDataArg,dataToIndexArg, status);
    }
  } // init

  command void MedianIndex.SetData[uint8_t inst]
    (uint8_t dataPos, uint8_t value, result_t *status)
  {
    uint8_t indexPos, newIndexPos;
    

    if ((numInst <= inst) || (data[inst] == NULL))
      *status = rcombine(*status,FAIL);
    else {
      data[inst][dataPos] = value;
      indexPos = dataToIndex[inst][dataPos];

      newIndexPos = MoveUp(inst,indexPos);
      if (newIndexPos != indexPos) {
        do {
          indexPos = newIndexPos;
          newIndexPos = MoveUp(inst,indexPos);
        } while (indexPos != newIndexPos);

      } else {
        newIndexPos = MoveDown(inst,indexPos);
        while (newIndexPos != indexPos) {
          indexPos = newIndexPos;
          newIndexPos = MoveDown(inst,indexPos);
        }
      }
    }
  } // SetData

  command ufix16_1_t MedianIndex.MedianValue[uint8_t inst](result_t *status)
  {
    uint8_t med, dataPos,dataPos0,dataPos1;
    ufix16_1_t result;

    if ((numInst <= inst) || (data[inst] == NULL)) {
      *status = rcombine(*status, FAIL);
      result = 0;

    } else {
      med = (len[inst] >> 1);
      if ( IsOddU8(len[inst]) ) {
        dataPos = indexToData[inst][med];
        result = (((uint16_t) data[inst][dataPos]) << 1); // ufix16_1_t cast
      } else {
        dataPos0 = indexToData[inst][med];
        dataPos1 = indexToData[inst][med - 1];
        result =
          ((uint16_t) data[inst][dataPos0] + (uint16_t) data[inst][dataPos1]);
      }

    }

    return result;
  } // MedianValue
} // implementation
