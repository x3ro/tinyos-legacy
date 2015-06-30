#include "CodeEntry.inc"

void CodeEntryInit(CodeEntry* this, uint8_t codeId, uint8_t minRange, 
						uint8_t maxRange)
{
	this->codeId = codeId;
	this->minRange = minRange;
	this->maxRange = maxRange;
	this->refCnt = 0;
}

char CodeEntryContains(CodeEntry* this, uint8_t codeId, 
						uint8_t minRange, uint8_t maxRange)
{

	return(this->codeId==codeId && minRange <= this->maxRange
			&& maxRange>=this->minRange);
}

char CodeEntryIsFree(CodeEntry *this)
{
  return (this->refCnt==0);
} 

void CodeEntryFree(CodeEntry *this) 
{
  this->refCnt=0;
}


