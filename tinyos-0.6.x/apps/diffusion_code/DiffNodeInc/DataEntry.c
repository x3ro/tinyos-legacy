#include "DataEntry.inc"

void DataEntryInit(DataEntry* this, 
			uint8_t x, uint8_t y, uint8_t codeId, 
			uint8_t frag, uint32_t orgSeqNum,
			uint8_t hopsToSrc, uint8_t prevHop)
{
  this->x = x;
  this->y = y;
	this->codeId=codeId;
	this->frag=frag;
  this->orgSeqNum = orgSeqNum;
  this->hopsToSrc = hopsToSrc;
  this->prevHop = prevHop;
}
