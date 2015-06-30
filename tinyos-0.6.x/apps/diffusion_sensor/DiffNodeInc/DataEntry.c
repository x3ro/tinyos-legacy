#include "DataEntry.inc"

void DataEntryInit(DataEntry* this, 
		   uint8_t x, uint8_t y, uint8_t type, uint32_t orgSeqNum,
		   uint8_t hopsToSrc, uint8_t prevHop, uint8_t data)
{
  this->x = x;
  this->y = y;
  this->type=type;
  this->orgSeqNum = orgSeqNum;
  this->hopsToSrc = hopsToSrc;
  this->prevHop = prevHop;
  this->data=data;
}
