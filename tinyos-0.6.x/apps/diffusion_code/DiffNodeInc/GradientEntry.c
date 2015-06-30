#include "GradientEntry.inc"

void GradientEntryInit(GradientEntry *this, InterestEntry *intref, 
						LocationEntry *locref, CodeEntry *coderef,
						unsigned char interval, unsigned char expiration)
{
	this->interestRef=intref;
	this->locationRef=locref;
	this->codeRef=coderef;
	this->expiration=expiration;
	this->interval=interval;
	this->curInterval=interval;
}


void GradientEntryFree(GradientEntry* this) {
  this->interestRef = NULL;
  this->locationRef = NULL;
	this->codeRef=NULL;
}

char GradientEntryIsFree(GradientEntry* this) {
  return ( this->interestRef == NULL
	   && this->locationRef== NULL 
		&& this->codeRef==NULL);
}
   
