// Library functions used to maintain the diffusion tables

#include "DiffTable.inc"

InterestEntry interestTable[MAX_INTERESTS];
GradientEntry gradientTable[MAX_GRADIENTS];
LocationEntry locationTable[MAX_LOCATIONS];


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
    
}

// Number after the fucntion name denotes number of arguments
// 'C's support for overloading :-)


// Find a gradient based on an interest
// and a filter match (location entry)
GradientEntry* findGradient2(InterestEntry* curInt, LocationEntry* curLoc)
{
  uint8_t i;
  GradientEntry* curGrad;

  for( i = 0; i < MAX_GRADIENTS; i++ ) {
    curGrad = & gradientTable[i];
    if( (curGrad->interestRef == curInt) && (curGrad->locationRef == curLoc) ) {
      return curGrad;
    }
  }
  return NULL;
}


// Find a gradient based on the type of an interest 
// and filter parameters (coordinates x and y)
GradientEntry* findGradient3(uint8_t type, uint8_t x, uint8_t y) {
  uint8_t i, i2;
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


// This function gives the output of a filter (location entry)
// based on filter-related input (coordinates)
LocationEntry* findLocation(uint8_t x1, uint8_t y1,
			    uint8_t x2, uint8_t y2)
{
  uint8_t i;
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


// Find an interest based on the interest's type
InterestEntry* findInterest(uint8_t type)
{
  uint8_t i;
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


// Decrement the lifetime of all gradients in the table and
// expire-remove them if necessary
void expireGradients(void)
{
  uint8_t i;
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



// Utility function that returns the next free element of the 
// interest table
InterestEntry* findFreeInterestEntry(void)
{
  uint8_t  i;

  for( i = 0; i < MAX_INTERESTS; i++ ) {
    if( InterestEntryIsFree( &interestTable[i] ) ) {
      return & interestTable[i];
    }
  }

  return NULL;
}


// Utility function that returns the next free element of the
// filter (location) table
LocationEntry* findFreeLocationEntry(void)
{
  uint8_t i;

  for( i = 0; i < MAX_LOCATIONS; i++ ) {
    if( LocationEntryIsFree( &locationTable[i] ) ) {
      return &locationTable[i];
    }
  }

  return NULL;
}


// Utility function that returns the next free element of
// the gradient table
GradientEntry* findFreeGradientEntry(void)
{
  uint8_t i;
  for( i = 0; i < MAX_GRADIENTS; i++ ) {
    if( GradientEntryIsFree( &gradientTable[i] ) ) {
      return &gradientTable[i];
    }
  }
  return NULL;
}


// Add a gradient to the gradient table based on 
// an interest element a filter element (location)
// and the attributes of the recently received interest
GradientEntry* addGradient(InterestEntry* curInt, LocationEntry* curLoc, 
			   uint8_t interval, uint8_t expiration, uint8_t range)
{
  GradientEntry* curGrad = findFreeGradientEntry();
  if( curGrad != NULL ) {
    GradientEntryInit(curGrad, curInt, curLoc, interval, expiration, range);
    curInt->refCnt++;
    curLoc->refCnt++;
  }

  return curGrad;
}


// self-explanatory
void removeGradient(GradientEntry* curGrad)
{
  curGrad->interestRef->refCnt--;
  curGrad->locationRef->refCnt--;

  GradientEntryFree(curGrad);
}







