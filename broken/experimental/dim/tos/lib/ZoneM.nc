module ZoneM {
  provides {
    interface Zone;
  }
}
implementation {
  Coord myCoord;
  Code myCode;
  uint16_t netBound[4], myZone[4];
  
  bool contain(uint16_t zone[4], Coord coo) {
    return (zone[0] <= coo.x && coo.x < zone[1] && 
            zone[2] <= coo.y && coo.y < zone[3]);
  }

  /*
  task void shrink() {
    uint16_t new_bound;
    uint8_t mask = 1 << ((sizeof(mask) * 8) - myCode.length - 1);
    
    while (contain(myZone, coord)) {
      if (myCode.length % 2 == 0) {
        // Partition parallel to Y-axis
        new_bound = (myZone[0] + myZone[1]) >> 1;
        if (myCoord.x < new_bound) {
          myZone[1] = new_bound;
        } else {
          myZone[0] = new_bound;
          myCode.word |= mask;
        }
      } else {
        // Partition parallel to X-axis
        new_bound = (myZone[2] + myZone[3]) >> 1;
        if (myCoord.y < new_bound) {
          myZone[3] = new_bound;
        } else {
          myZone[2] = new_bound;
          myCode.word |= mask;
        }
      }
      myCode.length++;
      mask >>= 1;
    }
    //dbg(DBG_USR2, "my zone is [%d, %d, %d, %d]\n", myZone[0], myZone[1], myZone[2], myZone[3]);
  }
  */

  void shrink(Coord coo) {
    uint16_t new_bound;
    uint8_t mask = 1 << ((sizeof(mask) * 8) - myCode.length - 1);
    
    while (contain(myZone, coo)) {
      if (myCode.length % 2 == 0) {
        // Partition parallel to Y-axis
        new_bound = (myZone[0] + myZone[1]) >> 1;
        if (myCoord.x < new_bound) {
          myZone[1] = new_bound;
        } else {
          myZone[0] = new_bound;
          myCode.word |= mask;
        }
      } else {
        // Partition parallel to X-axis
        new_bound = (myZone[2] + myZone[3]) >> 1;
        if (myCoord.y < new_bound) {
          myZone[3] = new_bound;
        } else {
          myZone[2] = new_bound;
          myCode.word |= mask;
        }
      }
      myCode.length++;
      mask >>= 1;
    }
    //dbg(DBG_USR2, "my zone is [%d, %d, %d, %d]\n", myZone[0], myZone[1], myZone[2], myZone[3]);
  }

  command result_t Zone.getCode(CodePtr codePtr) {
    codePtr->word = myCode.word;
    codePtr->length = myCode.length;
    return SUCCESS;
  }

  command result_t Zone.init(Coord coo) {
    uint8_t i;
    
    myCoord = coo;
    myCode.word = 0;
    myCode.length = 0;
    
    netBound[0] = 0;
    netBound[1] = MAXX;
    netBound[2] = 0;
    netBound[3] = MAXY;

    for (i = 0; i < 4; ++i) {
      myZone[i] = netBound[i];
    }

    //dbg(DBG_USR2, "my zone is [%d, %d, %d, %d]\n", myZone[0], myZone[1], myZone[2], myZone[3]);
    return SUCCESS;
  }
  
  command result_t Zone.adjust(Coord coo) {
    /*
    coord = coo;
    post shrink();
    */
    shrink(coo);
    return SUCCESS;
  }

  command result_t Zone.showCode(Code code, char *text) {
    if (text) {
      uint8_t mask = 1 << (sizeof(mask) * 8 - 1);
      if (code.length == 0) {
        strcpy(text, "NIL");
      } 
      else {
        uint8_t i;
        for (i = 0; i < code.length; i ++) {
          text[i] = ((mask & code.word) > 0) ? '1' : '0';
          mask >>= 1;
        }
        text[code.length] = 0;
      }
    }
    return SUCCESS;
  }

  /*
  * Parameter "upper" is temporarily omitted. But it is necessary for
  * encoding range queries.
  */
  command result_t Zone.encodeTuple(GenericTuplePtr gTuplePtr, uint8_t attrNum, CodePtr gCodePtr, bool mkUpper)
  {
    uint16_t unit = 1024; // 10 bits ADC readings, take 1024 as its maximum.
    uint8_t i, j;
    uint16_t k;
    uint8_t mask = 1 << (sizeof(mask) * 8 - 1);
    
    gCodePtr->length = 0;
    gCodePtr->word = 0;
    for (i = 0; i < myCode.length; i ++) {
      j = i % attrNum;
      if (j == 0) {
        unit >>= 1;
      }
      k = gTuplePtr->value[j] / unit;
      if (mkUpper) {
        // We are computing the upper bound for a range.
        if (k * unit == gTuplePtr->value[j]) {
          k --;
        }
      } 

      if (k % 2 == 0) {
        gCodePtr->word <<= 1;
      } else {
        gCodePtr->word = (gCodePtr->word << 1) | 1;
      }
      gCodePtr->length ++;
      if (
         ((gCodePtr->word & 1) > 0 && (myCode.word & mask) == 0)
         ||
         ((gCodePtr->word & 1) == 0 && (myCode.word & mask) > 0)
         ) {
        // Stop at the first different bit.
        break;
      }
      mask >>= 1;
      if (gCodePtr->length >= 8) {
        dbg(DBG_USR2, "Code length out of range!\n");
        break;
      }
    }
    // Move the code word to the most significant bits.
    k = sizeof(gCodePtr->word) * 8;
    gCodePtr->word = gCodePtr->word << (k - gCodePtr->length);
    
    return SUCCESS;
  }

  command result_t Zone.encodeQuery(GenericQueryPtr gQueryPtr, uint8_t attrNum, CodePtr gCodePtr)
  {
    uint8_t tupLowBuf[sizeof(GenericTuple) + attrNum * 2];
    uint8_t tupHiBuf[sizeof(GenericTuple) + attrNum * 2];

    GenericTuplePtr tupLowPtr = (GenericTuplePtr)tupLowBuf;
    GenericTuplePtr tupHiPtr = (GenericTuplePtr)tupHiBuf;

    Code codeLow, codeUp;
    uint8_t i;
    uint8_t mask = 1 << (sizeof(mask) * 8 - 1);

    for (i = 0; i < attrNum; i ++) {
      tupLowPtr->value[i] = gQueryPtr->queryField[i].lowerBound;
      tupHiPtr->value[i] = gQueryPtr->queryField[i].upperBound;
    }

    call Zone.encodeTuple(tupLowPtr, attrNum, &codeLow, FALSE);
    call Zone.encodeTuple(tupHiPtr, attrNum, &codeUp, TRUE);
    gCodePtr->length = 0;
    gCodePtr->word = 0;
    while (((mask & codeLow.word) == (mask & codeUp.word)) &&
           (gCodePtr->length < codeLow.length)) {
      if ((mask & codeLow.word) == 0) {
        gCodePtr->word <<= 1;
      } else {
        gCodePtr->word = (gCodePtr->word << 1) | 1;
      }
      gCodePtr->length ++;
      mask >>= 1;
    }
    // Move code word to the most significant bits.
    gCodePtr->word = gCodePtr->word << (sizeof(gCodePtr->word) * 8 - gCodePtr->length);
    return SUCCESS;
  }
    
  command result_t Zone.getAddress(Code code, CoordPtr coordPtr)
  {
    uint16_t dumyZone[4];
    uint8_t i, word, mask;
    
    for (i = 0; i < 4; i ++) {
      dumyZone[i] = netBound[i];
    }
    word = code.word;
    // mask = 1 << (sizeof(mask) *8 - 1);
    mask = 0x80;
    for (i = 0; i < code.length; i ++) {
      if ((word & mask) == 0) {
        // This bit is Zero.
        if (i % 2 == 0) {
          dumyZone[1] = (dumyZone[0] + dumyZone[1]) >> 1;
        } else {
          dumyZone[3] = (dumyZone[2] + dumyZone[3]) >> 1;
        }
      } else {
        // This bit is One.
        if (i % 2 == 0) {
          dumyZone[0] = (dumyZone[0] + dumyZone[1]) >> 1;
        } else {
          dumyZone[2] = (dumyZone[2] + dumyZone[3]) >> 1;
        }
      }
      word <<= 1;
    }
    coordPtr->x = (dumyZone[0] + dumyZone[1]) >> 1;
    coordPtr->y = (dumyZone[2] + dumyZone[3]) >> 1;
    return SUCCESS;
  }

  /*
  * Retrun TRUE if zone foo contains zone bar, i.e. zone bar is a 
  * subzone of zone foo. A zone always contains itself.
  */
  command bool Zone.subZone(Code foo, Code bar)
  {
    if (foo.length == 0) {
      return TRUE;
    }
    else if (foo.length == bar.length) {
      return (foo.word == bar.word);
    } 
    else if (bar.length < foo.length) {
      return FALSE;
    }
    else {
      uint8_t word = bar.word;
      uint8_t mask = 1 << (sizeof(mask) * 8 - 1);
      uint8_t i;

      for (i = 1; i < foo.length; i ++) {
        mask |= (mask >> 1);
      }

      return ((word & mask) == foo.word);
    }
  }
}
