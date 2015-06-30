#include "GradientEntry.inc"


// Initialize the gradient entry based on a refernce to an interest
// and a reference to a filter (location in this case)
void GradientEntryInit(GradientEntry* this, InterestEntry* intref,
		LocationEntry* locref, uint8_t interval, uint8_t expiration,
		uint8_t range)
{
	// Interest stuff goes here
	this->interestRef = intref;
	this->expiration = expiration;
	this->interval = interval;
	this->curInterval = interval;
	this->range = range;

	// Filter stuff goes here
	this->locationRef = locref;
}


void GradientEntryFree(GradientEntry* this) {
  this->interestRef = NULL;
  this->locationRef = NULL;
}



char GradientEntryIsFree(GradientEntry* this) {
  return ( this->interestRef == NULL
	   && this->locationRef== NULL);
}
