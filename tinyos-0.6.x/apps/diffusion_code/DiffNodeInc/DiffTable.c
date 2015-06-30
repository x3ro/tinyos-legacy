#include "DiffTable.inc"

InterestEntry interestTable[MAX_INTERESTS];
LocationEntry locationTable[MAX_LOCATIONS];
GradientEntry gradientTable[MAX_GRADIENTS];
CodeEntry codeTable[MAX_CODES];


void diffTableInit(void) {
  int cnt;

  for( cnt = 0; cnt < MAX_INTERESTS; cnt++ ) {
    InterestEntryFree( &interestTable[cnt] );
  }

  for( cnt = 0; cnt < MAX_GRADIENTS; cnt++ ) {
    GradientEntryFree(&gradientTable[cnt]);
  }

  for( cnt = 0; cnt < MAX_LOCATIONS; cnt++ ) {
    LocationEntryFree(&locationTable[cnt]);
  }
   
	for(cnt=0; cnt < MAX_CODES; cnt++) {
		CodeEntryFree(&codeTable[cnt]);
	}  
}

// Number after the fucntion name denotes number of arguments
// 'C's support for overloading :-)

GradientEntry* findGradient2( InterestEntry* curInt, LocationEntry* curLoc )
{
  unsigned char i;
  GradientEntry* curGrad;

  for( i = 0; i < MAX_GRADIENTS; i++ ) {
    curGrad = & gradientTable[i];
    if( (curGrad->interestRef == curInt) && (curGrad->locationRef == curLoc) ) {
      return curGrad;
    }
  }
  return NULL;
}


GradientEntry* findGradientCode(InterestEntry *curInt, LocationEntry *curLoc,
								CodeEntry *curCode)
{
	uint8_t i;
	GradientEntry *curGrad;
	
	for (i=0;i<MAX_GRADIENTS;i++) {
		curGrad=&gradientTable[i];
		if ((curGrad->interestRef==curInt) 
			&& (curGrad->locationRef==curLoc)
			&& (curGrad->codeRef==curCode)) {
				return curGrad;
		}
	}
	
	return NULL;
}	
			




GradientEntry* findGradient3( unsigned char type, unsigned char x, unsigned char y) {
  unsigned char i, i2;
  InterestEntry* curInt;
  LocationEntry* curLoc;
  GradientEntry* curGrad;

  curInt = findInterest(type);
  for( i = 0; i < MAX_LOCATIONS; i++ ) {
    curLoc = &locationTable[i];
    if( !LocationEntryIsFree(curLoc)
	&& LocationEntryDoesContain(curLoc, x, y) ) { 
      for( i2 = 0; i2 < MAX_GRADIENTS; i2++ ) {
	curGrad = &gradientTable[i2];
	if( !GradientEntryIsFree(curGrad)
	    && curGrad->expiration > 0 
	    && curGrad->interestRef == curInt 
	    && curGrad->locationRef == curLoc ) {
	  return curGrad;
	}
      }
    }
  }

  return NULL;
}


GradientEntry* findGradient3Code(uint8_t type, uint8_t x, uint8_t y, 
			uint8_t	codeId, uint8_t minRange, uint8_t maxRange)
{

	uint8_t i, j;
	InterestEntry *curInt;
	LocationEntry *curLoc;
	CodeEntry *curCode;
	GradientEntry *curGrad;

	curInt=findInterest(type);
	for (i=0; i< MAX_LOCATIONS; i++) {
		curLoc=&locationTable[i];
		curCode=&codeTable[i];
		if (LocationEntryIsFree(curLoc)==0
			&& LocationEntryDoesContain(curLoc, x, y)
			&& (CodeEntryIsFree(curCode)==0)
			&& CodeEntryContains(curCode, codeId, minRange, maxRange)) {
			
			for (j=0; j<MAX_GRADIENTS; j++) {
				curGrad=&gradientTable[j];
				if ((GradientEntryIsFree(curGrad)==0)
					&& curGrad->expiration > 0
					&& curGrad->interestRef==curInt
					&& curGrad->locationRef==curLoc
					&& curGrad->codeRef==curCode) {
					return curGrad;
				}
			}
		}
	}

	return NULL;
}
					



LocationEntry* findLocation(unsigned char x1, unsigned char y1,
			    unsigned char x2, unsigned char y2)
{
  unsigned char i;
  LocationEntry* curLoc;

  for( i = 0; i < MAX_LOCATIONS; i++ ) {
    curLoc = & locationTable[i];
      
    if( !LocationEntryIsFree(curLoc)
        && curLoc->x1 == x1
	&& curLoc->y1 == y1
	&& curLoc->x2 == x2
	&& curLoc->y2 == y2 ) {
      return curLoc;
    }
  }

  return NULL;
}


CodeEntry* findCode(uint8_t codeId, uint8_t minRange, uint8_t maxRange)
{
	uint8_t i;
	CodeEntry *curCode;

	for(i=0; i<MAX_CODES;i++) {
		curCode=&codeTable[i];
		
		if((CodeEntryIsFree(curCode)==0) 
			&& (curCode->codeId==codeId)
			&& (curCode->minRange==minRange)
			&& (curCode->maxRange==maxRange)) {
			return curCode;
		}
	}

	return NULL;
}
	
		


InterestEntry* findInterest(unsigned char type)
{
  unsigned char i;
  InterestEntry* curInt;

  for( i = 0; i < MAX_INTERESTS; i++ ) {
    curInt = & interestTable[i];

    if( !InterestEntryIsFree(curInt) 
	&& curInt->type == type ) {
      return curInt;
    }
  }

  return NULL;
}


void expireGradients(void)
{
  unsigned char i;
  GradientEntry* curGrad;

  for( i = 0; i < MAX_GRADIENTS; i++ ) {
    curGrad = & gradientTable[i];

    if( !GradientEntryIsFree(curGrad)
	&& curGrad->expiration <= 0 ) {
      removeGradient(curGrad);
    }
    else {
      curGrad->expiration--;
    }
  }
}


InterestEntry* findFreeInterestEntry(void)
{
  unsigned char  i;

  for( i = 0; i < MAX_INTERESTS; i++ ) {
    if( InterestEntryIsFree( &interestTable[i] ) ) {
      return & interestTable[i];
    }
  }

  return NULL;
}

LocationEntry* findFreeLocationEntry(void)
{
  unsigned char i;

  for( i = 0; i < MAX_LOCATIONS; i++ ) {
    if( LocationEntryIsFree( &locationTable[i] ) ) {
      return &locationTable[i];
    }
  }

  return NULL;
}


CodeEntry *findFreeCodeEntry()
{
	uint8_t i;
	
	for(i=0; i< MAX_CODES; i++) {
		if(CodeEntryIsFree(&codeTable[i])) {
			return &codeTable[i];
		}
	}

	return NULL;
}


GradientEntry* findFreeGradientEntry(void)
{
  unsigned char i;
  for( i = 0; i < MAX_GRADIENTS; i++ ) {
    if( GradientEntryIsFree( &gradientTable[i] ) ) {
      return &gradientTable[i];
    }
  }
  return NULL;
}




GradientEntry* addGradient(InterestEntry *curInt, LocationEntry *curLoc,
								CodeEntry *curCode, unsigned char interval,
								unsigned char expiration)
{
	GradientEntry *curGrad=findFreeGradientEntry();
	if (curGrad!=NULL) {
		GradientEntryInit(curGrad, curInt, curLoc, curCode,
								interval, expiration);
		curInt->refCnt++;
		curLoc->refCnt++;
		curCode->refCnt++;
	}
	return curGrad;
}



void removeGradient(GradientEntry* curGrad)
{
	curGrad->interestRef->refCnt--;
	curGrad->locationRef->refCnt--;
	curGrad->codeRef->refCnt--;

	GradientEntryFree(curGrad);
}
