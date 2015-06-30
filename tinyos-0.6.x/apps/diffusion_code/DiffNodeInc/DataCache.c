#include "DataCache.inc"

DataEntry cache[MAX_DATA];
unsigned char head;
unsigned char size;

#define ADVANCE(idx) idx=((idx+1 >= MAX_DATA)? 0 : idx+1)

void DataCacheInit(void)
{
  int cnt;
  size = 0;
  head = MAX_DATA-1;

  for( cnt = 0; cnt < MAX_DATA; cnt++ )
    {
      cache[cnt].hopsToSrc = -1;
    }
}

DataEntry* findFreeDataEntry(void)
{
  if( size < MAX_DATA )
    {
      size++;
    }

  ADVANCE(head);
  return (&cache[head]);
}


DataEntry* findExactData(unsigned char x, unsigned char y, uint8_t codeId, 
					uint8_t frag)
{
  unsigned char i;

  for( i = 0; i < size ; i++ )
    {
      if( (cache[i].x == x)
		&& (cache[i].y == y) 
		&& (cache[i].codeId==codeId)
		&& (cache[i].frag==frag))
	{
	  return (&cache[i]);
	}
    }

  return NULL;
}


DataEntry* findDataWithinRange(uint8_t x, uint8_t y, uint8_t codeId,
					uint8_t minRange, uint8_t maxRange)
{
	uint8_t i;

	for (i=0;i<size;i++) {
		if ((cache[i].x==x)
			&& (cache[i].y==y) 
			&& (cache[i].codeId==codeId)
			&& (cache[i].frag >= minRange)
			&& (cache[i].frag <= maxRange)) {
			return (&cache[i]);
		}
	}

	return NULL;
}

	
DataEntry* findDataSource(uint8_t codeId, uint8_t minRange, uint8_t maxRange)
{
	uint8_t i;
	
	for (i=0;i<size;i++) {
		if ((cache[i].codeId==codeId)
			&& (cache[i].frag >= minRange)
			&& (cache[i].frag <= maxRange)) {
			return (&cache[i]);
		}
	}

	return NULL;
}
		
