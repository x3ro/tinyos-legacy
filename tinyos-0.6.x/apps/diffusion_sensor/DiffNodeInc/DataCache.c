#include "DataCache.inc"

DataEntry cache[MAX_DATA];
uint8_t head;
uint8_t size;

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


DataEntry* findDataByLocation(uint8_t x, uint8_t y)
{
  uint8_t i;

  for( i = 0; i < size ; i++ )
    {
      if( (cache[i].x == x)
	  && (cache[i].y == y) )
	{
	  return (&cache[i]);
	}
    }

  return NULL;
}


DataEntry *findDataByThreshold(uint16_t threshold, uint8_t operator)
{
	uint8_t i;

	for (i=0;i<size;i++) {
		switch (operator) {
			case GT:
				if (cache[i].data>threshold) {
					return &cache[i];
				}
			break;
			case GE:
				if (cache[i].data>=threshold) {
					return &cache[i];
				}
			break;
			case LT:
				if (cache[i].data<threshold) {
					return &cache[i];
				}
			break;
			case LE:
				if (cache[i].data<=threshold) {
					return &cache[i];
				}
			case EQ:
				if (cache[i].data==threshold) {
					return &cache[i];
				}
			break;
			default:
				// Don't bother going through the whole array
				return NULL;
			break;
		}
	}

	return NULL;
}



DataEntry *findDataByType(uint8_t type)
{
	uint8_t i;

	for (i=0;i<size;i++) {
		if (cache[i].type==type)
			return &cache[i];
	}

	return NULL;
}
