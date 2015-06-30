#include "LocationEntry.inc"

void LocationEntryInit(LocationEntry* this, 
		       unsigned char x1, unsigned char y1,
		       unsigned char x2, unsigned char y2)
{
	this->x1 = x1;
	this->y1 = y1;
	this->x2 = x2;
	this->y2 = y2;
	this->refCnt = 0;
}

char LocationEntryDoesContain( LocationEntry* this, unsigned char x, unsigned char y )
{
  return ( this->x1 <= x && this->x2 >= x && this->y1 <= y && this->y2 >= y );
}

char LocationEntryIsFree(LocationEntry *this)
{
  return (this->refCnt==0);
} 

void LocationEntryFree(LocationEntry *this) 
{
  this->refCnt=0;
}


