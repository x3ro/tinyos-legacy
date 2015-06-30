/**
 * This is rather motley and low-level code
 * which implements bit vectors,
 * operations on them, and bit vector compression.  
 * Meant to store sets of ids of nodes.
 *
 * The compressed representation implements hybrid Run-Lengh
 * encoding, where "Literal" and "Fill" runs of bits encode the whole
 * string.
 * 
 * A "literal" run is, literally, a 4-bit snippet from the original bitvector.
 * A "fill" run encodes up to 32 consecutive identical bits from the
 * original string.
 *
 * An "index" of the encoded representation determines wether each
 * of the 4-bit encodings that follow is a literal or a fill representation.
 *
 * All operations except uncompressSet() can only be
 * performed on uncompressed sets.
 * 
 * @author Stan Rost
 * 
 **/

#ifndef __SR_COMPSET_H_
#define __SR_COMPSET_H_

/*
 * 
 * Maximums have been taken out of the picture!
 * Instead, use initSet to recast and initialize a buffer
*/

typedef struct {

  uint8_t aBit:1;

  // This counter is in units of 4 bits
  uint8_t aCnt:3;

  uint8_t bBit:1;

  // This counter is in units of 4 bits
  uint8_t bCnt:3;

} __attribute__ ((packed)) FillRun;

typedef struct {

  uint8_t aRun:4;
  uint8_t bRun:4;
  
} __attribute__ ((packed)) LitRun;


// Location in the Set bit [i] corresponds
// to the status of the node with address i
typedef struct {

  // is this a compressed bit vector?
  uint16_t compressed:1;
  
  // Does this set include a superskip header?
  // (pertinent to compressed sets only)
  uint16_t superSkip:1;

  // In uncompressed bit vectors, 
  // length, in bytes, of the non-zero elements.
  // 128 * 8 = 1024 nodes maximum

  // In compressed, this represents the
  // length of the index, in bytes.
  // Accordingly, the length of the bytes
  // is tightly bounded by len * 8 / 2 
  uint16_t len:14;

  // Start data
  uint8_t data[0];
  
} __attribute__ ((packed)) Set;

typedef struct {
  
  // What does the superskip encode?
  uint16_t ssBit:1;

  // Number of 4-bit spans that
  // superskip skips over...
  uint16_t ssLen:15;
  
} __attribute__ ((packed)) CompressedHeader;

// Max one can fit in 15 bits
#define MAX_SUPERSKIP_LEN (32767)


// Subtract s2 - s1, store in s1
void subtractSets(Set *s1,
		 Set *s2) {
  uint16_t i;

  if (s1 == NULL ||
      s2 == NULL)
    return;

  if (s1->len > s2->len) {
    // Length of s1 really does not change

    for (i = 0; i < s2->len; i++) {
      s1->data[i] &= ~(s2->data[i]);
    }

  } else {
    // Length of s1 might change
    uint16_t minLen;

    minLen = s1->len;
    s1->len = 0;

    for (i = 0; i < minLen; i++) {
      if ((s1->data[i] &= ~(s2->data[i])) != 0)
	s1->len = i+1;
    }

  }

}


// Is s2 a subset of s1?
// Is there any element of s2 that is not
// in s1?
bool containsSet(Set *s1, 
		 Set *s2) {
  uint16_t i;

  if (s1 == NULL ||
      s2 == NULL) {

    return FALSE;
  }

  if (s1->len < s2->len)
    return FALSE;

  for (i = 0; i < s2->len; i++) {

    if ((s1->data[i] | s2->data[i]) != s1->data[i])
      return FALSE;
  }

  return TRUE;
}

bool setsEqual(Set *s1, Set *s2) {
  uint16_t i;

  if (s1->len != s2->len)
    return FALSE;

  for (i = 0; i < s1->len; i++) {
    if (s1->data[i] != s2->data[i])
      return FALSE;
  }
  
  return TRUE;
}

// Count the number of 1 bits
uint8_t countBits(uint8_t n) {
  uint8_t i, bitCheck = 1, cnt = 0;

  for (i = 0; i < 8; i++) {
    if (n & bitCheck)
      cnt++;

    bitCheck <<=1;
  }

  return cnt;
}

uint16_t setLength(Set *s) {
  uint16_t i, res = 0;

  for (i = 0; i < s->len; i++) {
    res += countBits(s->data[i]);
  }

  return res;
}

// Calculate the resemblance (union
// over intersection)
// of the sets (in range 0-255)

// Hamming distance between bitmaps
uint16_t resemblance(Set *s1,
		     Set *s2) {
  uint16_t i, minLen;
  uint16_t intCnt = 0, unCnt = 0;

  if (s1 == NULL ||
      s2 == NULL)
    return 0;

  minLen = (s1->len > s2->len ? 
	    s2-> len : s1->len);

  // Intersection
  for (i = 0; i < minLen; i++) {
    intCnt += countBits(s1->data[i] & s2->data[i]);
    unCnt += countBits(s1->data[i] | s2->data[i]);
  }

  // Final calc
  if (unCnt > 0)
    return intCnt * ((uint16_t)0xFF) / ((uint16_t)(unCnt)); 
  else
    return 0xFF;
    
}

// Calculate the union of sets, store in s1
void unionSets(Set *s1,
	       Set *s2) {
  // Add all unique elements of s2 to s1
  uint16_t i, maxLen;

  if (s1 == NULL || s2 == NULL)
    return;

  maxLen = (s1->len > s2->len ?
	    s1->len : s2->len);

  // For every element of s2 that is not
  // in s1, add that element
  for (i = 0; i < maxLen; i++) {
    s1->data[i] |= s2->data[i];
  }

  s1->len = maxLen;

}

// Calculate the intersection of sets, store in s1
void intersectSets(Set *s1,
		   Set *s2) {
  // Add all unique elements of s2 to s1
  uint16_t i, minLen;

  if (s1 == NULL || s2 == NULL)
    return;

  minLen = (s1->len > s2->len ? 
	    s2-> len : s1->len);

  // For every element of s2 that is not
  // in s1, add that element
  for (i = 0; i < minLen; i++) {
    if ((s1->data[i] &= s2->data[i]) != 0)
      s1->len = i+1;
  }
}

// Initialize the set to blank
Set *initSet(uint8_t *buf, uint16_t szBytes) {
  Set *s = (Set *)buf;

  s->compressed = 0;
  s->len = 0;

  // Init all but the header
  memset(&s->data[0], 0, szBytes - (sizeof(Set) - sizeof(s->data)));

  return s;
}

// Size in bytes
uint16_t sizeOfSet(Set *s) {
  if (s->compressed)
    // Size of index, nubmer of bytes and header
    return (s->len + s->len * 8 / 2 + (sizeof(Set) - sizeof(s->data) + 
				       (s->superSkip ? 
					sizeof(CompressedHeader) 
					: 0)));
  else
    // Number of bytes and header
    return (s->len + (sizeof(Set) - sizeof(s->data)));
}

void copySet(Set *dst, Set *src) {
  memcpy(dst, src, sizeOfSet(src));
}

void markBitArray(uint8_t *arr, uint16_t loc, bool val) {
  uint16_t whichByte = (loc >> 3), 
    whichBit = loc - (whichByte << 3);

  if (val) 
    arr[whichByte] |= (1 << whichBit);
  else
    arr[whichByte] &= ~(1 << whichBit);
}
 
void setBit(Set *s, uint16_t loc) {
  markBitArray(s->data, loc, TRUE);

  if (s->len < (loc / 8 + 1)) {

    s->len = loc / 8 + 1;

  }
}

bool testBitArray(uint8_t *arr, uint16_t loc) {
  uint16_t whichByte = (loc >> 3), 
    whichBit = loc - (whichByte << 3);
  
  return ((arr[whichByte] & (1 << whichBit))
	  != 0 ? TRUE : FALSE);

}

void clearBit(Set *s, uint16_t loc) {
  markBitArray(s->data, loc, FALSE);

  while (loc > 0 &&
	 testBitArray(s->data, loc) == FALSE) loc--;

  // Scan left until hit a set bit
  if (s->len > (loc / 8 + 1)) {
    s->len = loc / 8 + 1;
  }
}


bool testBit(Set *s, uint16_t loc) {

  if ((loc + 7) / 8 >= s->len)
    return FALSE;

  return testBitArray(s->data, loc);
}


void insertIntoSet(Set *s, uint16_t addr) {

  setBit(s, addr);
}

// Membership test
bool testSet(Set *s, uint16_t addr) {
  return testBit(s, addr);
}

// Calculate the projected length of the
// compressed bitmap, initialize the index length
// of the compressed set, and return whether
// it saves bytes to compress the set (TRUE if so).
// byteLength stores the projected length of the set, in bytes
bool preprocessSet(Set *s, 
		   uint16_t *resultLen, 
		   uint16_t *indexLen) {

  // Index in the compressed representation
  uint16_t compByte = 0xFFFF;
  uint8_t compHalf = 1;

  // Last byte where values are non-zero
  uint16_t payloadLen = 0;

  // Index in the uncompressed representation
  uint16_t uncByte = 0;
  uint8_t uncHalf = 0;

  // The current byte under consideration
  uint8_t cur, _prev = 0;
  uint16_t prevCount = 0;

  // Superskip block available
  bool ssAvail = TRUE, ssUsed = FALSE;

  for (uncByte = 0; uncByte < s->len; uncByte++) {
    for (uncHalf = 0; uncHalf < 2; uncHalf++) {
      bool repeat = FALSE;

      cur = (s->data[uncByte] >> (uncHalf * 4)) & 0xF;

      repeat = (cur == _prev &&
		(cur == 0x0 ||
		 cur == 0xF) &&
		(uncByte + uncHalf));
		
      if (ssAvail &&
	  repeat &&
	  prevCount < MAX_SUPERSKIP_LEN) {
	ssUsed = TRUE;
	prevCount++;
      } else if (repeat &&
		 prevCount < 7) {
	// Append to the previous
	
	if (compHalf == 0) {
	  prevCount++;
	} else {
	  prevCount++;
	}
	
      } else if (cur == 0xF ||
		 cur == 0x0) {
	// New fill
	
	compHalf++;
	if (compHalf == 2) {
	  compHalf = 0;
	  compByte++;
	}
	
	if (compHalf == 0) {
	  prevCount = 1;
	} else {
	  prevCount = 1;
	}
	
	if (uncHalf + uncByte > 0)
	  ssAvail = FALSE;

	if (cur == 0xF) {
	  payloadLen = (compByte + compHalf);
	}

      } else {
	// Literal
	
	compHalf++;
	if (compHalf == 2) {
	  compHalf = 0;
	  compByte++;
	  
	}

	// This record is full
	prevCount = 8;
	
	ssAvail = FALSE;

	payloadLen = (compByte + compHalf);
	
      }
      
      _prev = cur;
    }
  }
  
  //  printf("ssUsed = %d\n", ssUsed);
  
  compHalf++;
  if (compHalf == 2) {
    compHalf = 0;
    compByte++;  
  }

  // Length of the compressed vector's index
  // Each bit of the compressed index describes 4 bits of the
  // compressed byte
  // compHalf indicates whether the current byte is in use
  *indexLen = ((compByte * 2 + compHalf) + 7) / 8;

  // prevCount now holds the projected length
  // of the compressed set, sanes the size of the set
  // data structure

  /*
  dbg(DBG_USR1, "XXX:  indexLen = %d, payloadLen = %d, compH = %d\n", 
      *indexLen, 
      payloadLen,
      (ssUsed ? sizeof(CompressedHeader) : 0));
  */

  prevCount = *indexLen + payloadLen + (ssUsed ? sizeof(CompressedHeader) : 0);

  /*
  dbg(DBG_USR1, "XXX:  prevCount = %d, s->len = %d\n", prevCount, s->len);
  */

  // Is the compressed representation more compact?
  if (prevCount  < s->len) {

    *resultLen = 
      (prevCount + 
       sizeof(Set) - sizeof(s->data));

    return TRUE;
  } else {

    *resultLen = sizeOfSet(s);
    
    return FALSE;
  }

}

// What is the maximum size of a compressed
// set given that its index is this long?
uint16_t maxCompressedLen(uint16_t idxLen) {
  Set *s;
  
  return (idxLen + idxLen * 8 / 2 + 
	  (sizeof(Set) - sizeof(s->data) + 
	   sizeof(CompressedHeader)));
}

// Given a compressed set, what is its decompressed length?
uint16_t maxDecompressedLen(Set *cs) {
  FillRun *fr = NULL;

  // Index in the compressed representation
  uint16_t compByte = 0;
  uint8_t compHalf = 0;

  uint16_t halfBytes = 0;

  // Other
  uint8_t cur;

  // Pointers into the compressed set
  uint8_t *compIndex = NULL, *compData = NULL;

  if (cs->compressed == 0)
    return sizeOfSet(cs);

  // Unravel the superSkip chunk
  if (cs->superSkip) {
    CompressedHeader *ch = (CompressedHeader *)&cs->data[0];

    compIndex = &cs->data[sizeof(CompressedHeader)],
    compData = &cs->data[sizeof(CompressedHeader) + cs->len];

    halfBytes += ch->ssLen;
  } else {
    compIndex = &cs->data[0],
    compData = &cs->data[cs->len];
  }

  for (compByte = 0; compByte < cs->len * 8 / 2; compByte++) {
    for (compHalf = 0; compHalf < 2; compHalf++) {

      if (testBitArray(compIndex,
		       compByte * 2 + compHalf)) {
	cur = (compData[compByte] >> (compHalf * 4)) & 0xF;

	// This is a fill run
	fr = (FillRun *)&cur;	
	halfBytes += fr->aCnt;
	
      } else {
	halfBytes++;
      }
    }
  }

  return sizeof(Set) - sizeof(cs->data) + (halfBytes + 1) / 2;
}

// Compression works on the half-byte
// chunks of literal runs, encoding them as such in
// the compressed array.
// CompressedSet should already have its
// index length set via precompressSet().
void compressSet(Set *s, Set *cs, uint16_t indexLen) {

  // Some storage helpers
  LitRun *lr = NULL;
  FillRun *fr = NULL;

  // Index in the compressed representation
  uint16_t compByte = 0xFFFF;
  uint8_t compHalf = 1;

  // Index in the uncompressed representation
  uint16_t uncByte = 0;
  uint8_t uncHalf = 0;

  // The current half under consideration
  uint8_t cur, _prev = 0;
  uint16_t prevCount = 0;

  // Pointers into the compressed set
  uint8_t *compIndex,
    *compData;

  bool ssAvail = TRUE;

  CompressedHeader *ch = (CompressedHeader *)&cs->data[0];

  // Initialize
  cs->len = indexLen;

  // Don't know if we will use the superskip
  cs->superSkip = 0;

  compIndex = &cs->data[0];

  // Initialize the compIndex
  memset(compIndex, 0, cs->len);

  compData = &cs->data[cs->len];
  memset(compData, 0, cs->len * 8 / 2);

  /*
    printf("CSet is at %p, index is at %p, data is at %p\n",
    cs,
    compIndex,
    compData);
  */

  fr = (FillRun *)&compData[0];
  lr = (LitRun *)&compData[0];
    
  cs->compressed = TRUE;

  for (uncByte = 0; uncByte < s->len; uncByte++) {
    for (uncHalf = 0; uncHalf < 2; uncHalf++) {
      bool repeat = FALSE, span = FALSE;

      cur = (s->data[uncByte] >> (uncHalf * 4)) & 0xF;


      /*
	printf("\n-- Cur [byte =%u, half =%u, compByte = %u, compHalf = %u ]\n", 
	uncByte, uncHalf, compByte, compHalf);
	printBits(cur);
	printf("\nPrev:");
	printBits(_prev);
	printf("\n");
      */

      span = (cur == 0x0 ||
	      cur == 0xF);

      repeat = (cur == _prev &&
		(uncByte  > 0 ||
		 uncHalf > 0));

      if (ssAvail &&
	  span &&
	  repeat &&
	  prevCount < MAX_SUPERSKIP_LEN) {
	
	if (cs->superSkip == 0) {
	  cs->superSkip = 1;
	  ch->ssBit = (cur == 0xF ? 1 : 0);
	  ch->ssLen = 1;
	  
	  compIndex = &cs->data[sizeof(CompressedHeader)];
	  compData = &cs->data[sizeof(CompressedHeader) + cs->len];

	  memset(compIndex, 0, cs->len);
	  memset(compData, 0, cs->len * 8 / 2);
	  
	  //	  printf("\n-- Initializing superSkip of bit %d\n", ch->ssBit);
	}
	
	ch->ssLen++;
	
	/*
	  printf("\n-- Inflating superSkip of bit %d to %d\n", 
	  ch->ssBit, ch->ssLen); 
	*/	  

	// Reset the compressed index
	compHalf = 1;
	compByte = 0xFFFF;
	
	//	  printf("Pumping superSkip to %u\n", ch->ssLen);
	
      } else if
	(span &&
	 repeat && 
	 prevCount < 7) {
	// Append to the previous
	
	fr = (FillRun *)&compData[compByte];
	lr = (LitRun *)&compData[compByte];
	
	//	printf("compByte: %u, FR: %p, LR: %p\n", compByte, fr, lr);
	
	if (compHalf == 0) {
	  fr->aCnt++;
	  prevCount++;
	} else {
	  fr->bCnt++;
	  prevCount++;
	}
	
	//	printf("\nAppend to previous, prevCount now %u\n", prevCount);

      } else if (span) {
	// New fill

	//	printf("\nNew fill of %u\n", cur);

	compHalf++;
	if (compHalf == 2) {
	  compHalf = 0;
	  compByte++;
	  
	  fr = (FillRun *)&compData[compByte];
	  lr = (LitRun *)&compData[compByte];
	}
	
	if (compHalf == 0) {

	  fr->aBit = (cur & 1);
	  fr->aCnt = 1;
	  prevCount = 1;
	} else {
	  fr->bBit = (cur & 1);
	  fr->bCnt = 1;
	  prevCount = 1;
	}

	// Mark this one as an RLE "run" in the index field
	markBitArray(compIndex, 
		     compByte * 2 + compHalf, TRUE);

	if (uncByte + uncHalf > 0)
	  ssAvail = FALSE;
      } else {
	// Literal

	/*
	printf("\nLiteral of \n");
	printBits(cur);
	printf("\n");
	*/

	compHalf++;
	if (compHalf == 2) {
	  compHalf = 0;
	  compByte++;

	  fr = (FillRun *)&compData[compByte];
	  lr = (LitRun *)&compData[compByte];
	}
	  
	if (compHalf == 0) {
	  lr->aRun = cur;
	} else {
	  lr->bRun = cur;
	}

	// This one is a literal "run"
	markBitArray(compIndex,
		     compByte *2 + compHalf, FALSE);

	// This record is full
	prevCount = 8;

	ssAvail = FALSE;

      }

      /*
      printf("-- Bitmap is now:\n");
      printSetBits(cs);
      printf("\n");
      */
      
      _prev = cur;

    }
  }

}

void trimSet(Set *s) {
  uint16_t i;

  if (s->compressed)
    return;

  for (i = s->len - 1; i != 65535LU; i--)
    if (s->data[i] != 0) {
      s->len = i + 1;

      return;
    }
}

void decompressSet(Set *cs, Set *s) {
  // Some storage helpers
  LitRun *lr = NULL;
  FillRun *fr = NULL;

  // Index in the compressed representation
  uint16_t compByte = 0;
  uint8_t compHalf = 0;

  // Index in the uncompressed representation
  uint16_t uncByte = 0;
  uint8_t uncHalf = 0;

  // Other
  uint8_t cur, i;

  // Pointers into the compressed set
  uint8_t *compIndex = NULL, *compData = NULL;

  if (cs->compressed == 0) {

    copySet(s, cs);

    return;
  }

  // Initialize the target
  s->compressed = FALSE;
  s->superSkip = FALSE;

  // Unravel the superSkip chunk
  if (cs->superSkip) {
    CompressedHeader *ch = (CompressedHeader *)&cs->data[0];

    uint16_t j;
    uint8_t fill = (ch->ssBit ? 0x0F : 0x00);

    compIndex = &cs->data[sizeof(CompressedHeader)],
    compData = &cs->data[sizeof(CompressedHeader) + cs->len];

    /*
    dbg(DBG_USR1, 
	"Unraveling superSkip of bit %u, length %u\n", 
	ch->ssBit, ch->ssLen);
    */

    for (j = 0; j < ch->ssLen; j++) {
      lr = (LitRun *)&s->data[uncByte];

      if (uncHalf == 0) {
	lr->aRun = fill;

	uncHalf = 1;
      } else {
	lr->bRun = fill;

	uncHalf = 0;
	uncByte++;
      }

    }
  } else {
    compIndex = &cs->data[0],
    compData = &cs->data[cs->len];
  }

  for (compByte = 0; compByte < cs->len * 8 / 2; compByte++) {
    for (compHalf = 0; compHalf < 2; compHalf++) {

      cur = (compData[compByte] >> (compHalf * 4)) & 0xF;

      /*
      dbg(DBG_USR1, 
	  "\n-- Cur [byte = %u, half = %u, uncByte =%d, uncHalf = %d ] = %u\n", 
	  compByte, compHalf, uncByte, uncHalf, cur);
      printBits(cur);
      dbg_clear(DBG_USR1, "\n");
      */

      if (testBitArray(compIndex,
		       compByte * 2 + compHalf)) {

	// This is a fill run
	fr = (FillRun *)&cur;
	lr = (LitRun *)&s->data[uncByte];
	
	/*
	dbg(DBG_USR1,
	    "\n Fill run of %u runs of bit %u\n", fr->aCnt, fr->aBit);
	*/

	if (fr->aBit) {

	  for (i = 0; i < fr->aCnt; i++) {
	    
	    if (uncHalf == 0) {
	      s->data[uncByte] = 0;

	      lr->aRun = 0xF;

	      uncHalf = 1;
	    } else {
	      lr->bRun = 0xF;

	      uncHalf = 0;
	      uncByte++;

	      lr = (LitRun *)&s->data[uncByte];
	    }
	    
	  }
	} else {

	  for (i = 0; i < fr->aCnt; i++) {
	    if (uncHalf == 0) {
	      s->data[uncByte] = 0;

	      lr->aRun = 0;

	      uncHalf = 1;
	    } else {
	      lr->bRun = 0;

	      uncHalf = 0;
	      uncByte++;

	      lr = (LitRun *)&s->data[uncByte];
	    }
	    
	  }
	}
	
      } else {
	// This is a literal run
	LitRun *lr2 = (LitRun *)&s->data[uncByte];

	if (uncHalf == 0) {
	  s->data[uncByte] = 0;

	  lr2->aRun = cur;

	  uncHalf = 1;
	} else {
	  lr2->bRun = cur;

	  uncHalf = 0;
	  uncByte++;
	  
	  lr = (LitRun *)&s->data[uncByte];
	}

      }
    }
  }
  
  // (SAR)  This is correct
  s->len = uncByte + uncHalf;

  //  dbg(DBG_USR1, "Before trimSet the length is %d\n", s->len);

  trimSet(s);

  // dbg(DBG_USR1, "After trimSet the length is %d\n", s->len);

}

#if !defined(PLATFORM_MICA2) && !defined(PLATFORM_MICA2DOT) && !defined(PLATFORM_CRICKET) && !defined(PLATFORM_PC)
void printBits(uint8_t n) {  
  uint8_t i;
  
  for (i = 0; i < 8; i++) {
    if (i % 4 == 0) {
      printf(" ");
    }
    
    printf("%d", ((n & (1 << i)) ? 1 : 0));
    
  }
}

void printSetBits(Set *s) {
  uint16_t i;
  
  if (s == NULL) {
    printf( "Set is NULL\n");
    
    return;
  }

  printf("\n---------------------------\n\n");
  
  if (s->compressed == 0) {
    printf( "Uncompressed bits: \n");
    for (i = 0; i < s->len; i++) {
      printBits(s->data[i]);
    }
    printf("\n");
  } else {
    uint8_t *data;

    if (s->superSkip) {
      CompressedHeader *ch = (CompressedHeader *)&s->data[0];

      printf("* SuperSkip: filling %u spans of bit %u\n",
	     ch->ssLen,
	     ch->ssBit);
      data = &s->data[sizeof(CompressedHeader)];
    } else {
      printf("* SuperSkip omitted\n");
      data = &s->data[0];
    }
    
    printf( "* Compressed index (%d): \n",
	    s->len);
    
    for (i = 0; i < s->len; i++) {
      printBits(data[i]);
    }
    
    printf("\n");
    printf( "* Compressed codewords: \n");
    
    for (i = s->len; 
	 i < s->len + (s->len * 8 / 2); i++) {
      printBits(data[i]);
    }
    
    printf("\n");
  }

  printf("\n---------------------------\n\n");

}


void printSet(Set *s) {
  uint16_t i, j, k =0;
 
  if (s == NULL) {
    printf("Set is NULL\n");
  } else {
    printf("Set (comp=%d, len=%d): ",
	   s->compressed,
	   s->len);
    
    if (!s->compressed) {
      for (i = 0; i < s->len; i++) {
	for (j = 0; j < 8; j++) {
	  if (s->data[i] & (1 << j))
	    printf("%d ", k);
	  k++;
	}
      }
      printf("\n");
    } else {
      printf("Compressed set printing unsupported\n");
    }
  }

}

#elif defined(PLATFORM_PC)

void printBits(uint8_t n) {  
  uint8_t i;
  
  for (i = 0; i < 8; i++) {
    if (i % 4 == 0) {
      dbg_clear(DBG_USR1, " ");
    }
    
    dbg_clear(DBG_USR1, "%d", ((n & (1 << i)) ? 1 : 0));
    
  }
}

void printSetBits(Set *s) {
  uint16_t i;
  
  if (s == NULL) {
    dbg(DBG_USR1,  "Set is NULL\n");
    
    return;
  }

  dbg(DBG_USR1, "\n---------------------------\n\n");
  
  if (s->compressed == 0) {
    dbg(DBG_USR1,  "Uncompressed bits (len = %d): \n", s->len);
    for (i = 0; i < s->len; i++) {
      printBits(s->data[i]);
    }
    dbg_clear(DBG_USR1, "\n");
  } else {
    uint8_t *data;

    if (s->superSkip) {
      CompressedHeader *ch = (CompressedHeader *)&s->data[0];

      dbg(DBG_USR1, "* SuperSkip: filling %u spans of bit %u\n",
	     ch->ssLen,
	     ch->ssBit);
      data = &s->data[sizeof(CompressedHeader)];
    } else {
      dbg(DBG_USR1, "* SuperSkip omitted\n");
      data = &s->data[0];
    }
    
    dbg(DBG_USR1,  "* Compressed index (%d): \n",
	    s->len);
    
    for (i = 0; i < s->len; i++) {
      printBits(data[i]);
    }
    
    dbg_clear(DBG_USR1, "\n");
    dbg(DBG_USR1,  "* Compressed codewords: \n");
    
    for (i = s->len; 
	 i < s->len + (s->len * 8 / 2); i++) {
      printBits(data[i]);
    }
    
    dbg_clear(DBG_USR1, "\n");
  }

  dbg(DBG_USR1, "\n---------------------------\n\n");

}


void printSet(Set *s) {
  uint16_t i, j, k =0;
 
  if (s == NULL) {
    dbg(DBG_USR1, "Set is NULL\n");
  } else {
    dbg(DBG_USR1, "Set (comp=%d, len=%d): ",
	   s->compressed,
	   s->len);
    
    if (!s->compressed) {
      for (i = 0; i < s->len; i++) {
	for (j = 0; j < 8; j++) {
	  if (s->data[i] & (1 << j))
	    dbg_clear(DBG_USR1, "%d ", k);
	  k++;
	}
      }
      dbg_clear(DBG_USR1, "\n");
    } else {
      dbg(DBG_USR1, "Compressed set printing unsupported\n");
    }
  }

}

void testBug() {
  char *bugNot = "0111001110000111000111111111111110000000", *iter;
  Set *orig, *comp, *new;
  uint8_t *origData, *compData, *newData;
  uint8_t i;
  uint16_t projLen, idxLen;

  origData = (uint8_t *)malloc(20);
  newData = (uint8_t *)malloc(20);
  
  orig = initSet(origData, 20);
  new = initSet(newData, 20);
  
  for (iter = bugNot, i = 0; *iter; iter++, i++) {
    if (*iter == '1')
      setBit(orig, i);
  }

   // Now, test compression
  if (preprocessSet(orig, &projLen, &idxLen)) {
    compData = (uint8_t *)malloc(maxCompressedLen(idxLen));

    comp = initSet(compData, projLen);
    
    compressSet(orig, comp, idxLen);
  } else {
    compData = (uint8_t *)malloc(maxCompressedLen(idxLen));
    
    comp = initSet(compData, projLen);
    
    copySet(comp, orig);
  }    
  
  decompressSet(comp, new);
  
  if (!setsEqual(orig, new)) {
    dbg(DBG_USR1, "VIOLATION!!!!\n");
    
    dbg(DBG_USR1, "Old set:\n");
    printSetBits(orig);
    dbg_clear(DBG_USR1, "\n");
    
    dbg(DBG_USR1, "Compressed set:\n");
    printSetBits(comp);
    dbg_clear(DBG_USR1, "\n");
    
    dbg(DBG_USR1, "New set:\n");
    printSetBits(new);
    dbg_clear(DBG_USR1, "\n");
    
    exit(-1);
    
  }
  
  free(orig);
  free(new);
  free(comp);

}

void testSets() {
  Set *orig, *comp, *new;
  uint8_t *origData, *compData, *newData;

  uint32_t sizeBits, numBits; 
  uint16_t i, j;
  uint16_t projLen, idxLen;

  srand(time(NULL));

#define MAX_TEST 65535
  for (i = 0; i < MAX_TEST; i++) {
    uint16_t byteSize;

    sizeBits = random() % ((20 - sizeof(Set) + sizeof(orig->data)) * 8) + 1;
    numBits = random() % sizeBits + 1;

    byteSize = (sizeBits + 7) / 8 + sizeof(Set) - sizeof(orig->data);

    origData = (uint8_t *)malloc(byteSize);
    orig = initSet(origData, byteSize);

    for (j = 0; j < sizeBits; j++) {
      setBit(orig, random() % sizeBits);
    }

    dbg(DBG_USR1, "Now testing: %d/%d, size of %d bits (%d bytes), %d bits\n",
	i, MAX_TEST, sizeBits, byteSize, numBits);

    // Now, test compression
    if (preprocessSet(orig, &projLen, &idxLen)) {
      compData = (uint8_t *)malloc(maxCompressedLen(idxLen));

      comp = initSet(compData, projLen);

      compressSet(orig, comp, idxLen);
    } else {
      compData = (uint8_t *)malloc(maxCompressedLen(idxLen));

      comp = initSet(compData, projLen);

      copySet(comp, orig);
    }    

    byteSize = maxDecompressedLen(comp);

    newData= (uint8_t *)malloc(byteSize);
    new = initSet(newData, byteSize);

    decompressSet(comp, new);

    if (!setsEqual(orig, new)) {
      dbg(DBG_USR1, "VIOLATION!!!!\n");

      dbg(DBG_USR1, "Old set:\n");
      printSetBits(orig);
      dbg_clear(DBG_USR1, "\n");

      dbg(DBG_USR1, "Compressed set:\n");
      printSetBits(comp);
      dbg_clear(DBG_USR1, "\n");

      dbg(DBG_USR1, "New set:\n");
      printSetBits(new);
      dbg_clear(DBG_USR1, "\n");

      exit(-1);

    }
    
    free(comp);
    free(origData);
    free(newData);
  }

}

#else


void printBits(uint8_t n) {  
}

void printSetBits(Set *s) {
}


void printSet(Set *s) {
}

void testSets() {

}

#endif
 

#endif
