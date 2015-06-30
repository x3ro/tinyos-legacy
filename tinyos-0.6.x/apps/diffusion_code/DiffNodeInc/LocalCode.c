#include "LocalCode.inc"

uint8_t LocalCodeInit(struct Code * code, uint8_t codeId,
							uint8_t minRange, uint8_t maxRange) 
{
	uint8_t i;
	if (code==NULL || minRange>maxRange || maxRange>MAX_FRAGS)	
		return 0;

	code->ID=codeId;
	for (i=minRange; i<maxRange; i++) {
		code->frag[i]=i;
	}

	code->is_full=(maxRange-minRange) / MAX_FRAGS;
	
	return i-minRange;
}	
