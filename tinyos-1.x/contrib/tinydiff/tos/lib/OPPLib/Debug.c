// Implementation file for debugging TinyDiffusion

#include "dbg.h"
#include "Debug.h"
#include "string.h"

// for the PC platform, these functions have implementations.. for non-PC
// platforms, these functions are empty...

#ifdef PLATFORM_PC

// Print Attribute
void prAtt(uint32_t dbgLevel, BOOL includeHeader, Attribute *att, uint8_t num)
{
  if (includeHeader)
  {
    dbg(dbgLevel, "----------------------ATTRIBUTE---------------------\n");
  }

  dbg(dbgLevel, "Att# %d: key: %d op: %d value: %d\n", 
	  num, att->key,att->op,att->value);

  if (includeHeader)
  {
    dbg(dbgLevel, "----------------------------------------------------\n");
  }
} 

// Print AttributeArray

void prAttArray(uint32_t dbgLevel, BOOL includeHeader, Attribute *att, uint8_t AttNum)
{
  uint8_t i ; // loop index

  if (includeHeader)
  {
    dbg(dbgLevel, "--------------------ATTRIBUTE ARRAY-------------------\n");
  }

  dbg(dbgLevel, "Attnum: %d\n", AttNum);

  for ( i = 0; i < AttNum; i++)
  {
    prAtt(dbgLevel, FALSE, &att[i], i);
  }

  if (includeHeader)
  {
    dbg(dbgLevel, "------------------------------------------------------\n");
  }
}

// Print Interest Message
void prIntMes(uint32_t dbgLevel, BOOL includeHeader, InterestMessage * m)
{

  if (includeHeader)
  {
    dbg(dbgLevel, "--------------------INTEREST MESSAGE-------------------\n");
  }
  dbg(dbgLevel, "Interest Message:\n");
  dbg(dbgLevel, "sink: %d seq: %d prev: %d ttl: %d exp: %d\n",
      m->sink, m->seqNum, m->prevHop, m->ttl, m->expiration);
  dbg(dbgLevel, "\n");

  prAttArray(dbgLevel, FALSE, m->attributes, m->numAttrs);

  if (includeHeader)
  {
    dbg(dbgLevel, "------------------------------------------------------\n");
  }
}

// Print Data Message
void prDataMes(uint32_t dbgLevel, BOOL includeHeader, DataMessage * m)
{
  if (includeHeader)
  {
    dbg(dbgLevel, "----------------------DATA MESSAGE---------------------\n");
  }

  dbg(dbgLevel, "Data Message:\n");
  dbg(dbgLevel, "seq: %d src: %d prev: %d hops2src: %d\n", 
      m->seqNum,m->source, m->prevHop, m->hopsToSrc);
  dbg(dbgLevel, "\n");

  prAttArray(dbgLevel, FALSE, m->attributes, m->numAttrs);

  if (includeHeader)
  {
    dbg(dbgLevel, "------------------------------------------------------\n");
  }
}


// Print Data Cache
void prDataCache(uint32_t dbgLevel, BOOL includeHeader, DataCache * dc)
{
  uint8_t i;

  if (includeHeader)
  {
    dbg(dbgLevel, "-----------------------DATA CACHE----------------------\n");
  }
  dbg(dbgLevel, "DataCache: \n");
  for (i = 0; i < MAX_DATA; i++)
  {
    if (dc->entries[i].source != NULL_NODE_ID)
    {
      dbg(dbgLevel, "seq: %d src: %d\n", 
	  dc->entries[i].seqNum, dc->entries[i].source);
    }
  }

  if (includeHeader)
  {
    dbg(dbgLevel, "------------------------------------------------------\n");
  }

}

// Print Gradient Entry
void prGrad(uint32_t dbgLevel, BOOL includeHeader, InterestGradient *G, int num)
{
  if (includeHeader)
  {
    dbg(dbgLevel, "------------------------GRADIENT-----------------------\n");
  }

  dbg(dbgLevel, "Grad# %d: exp: %d prev: %d\n",
	  num, G->expiration, G->prevHop); 

  if (includeHeader)
  {
    dbg(dbgLevel, "------------------------------------------------------\n");
  }
}

// Print Interest Entry
void prIntEnt(uint32_t dbgLevel, BOOL includeHeader, InterestEntry * ie)
{
  uint8_t i;

  if (includeHeader)
  {
    dbg(dbgLevel, "---------------------INTEREST ENTRY--------------------\n");
  }
  dbg(dbgLevel, "numGradients = %d; subHandle = %d\n", ie->numGradients,
      ie->subHandle);
  dbg(dbgLevel, "\n");
  prIntMes(dbgLevel, FALSE, &ie->interest);
  
  if (ie->numGradients > 0)
  {
    dbg(dbgLevel, "\n");
  }
  for (i = 0; i < ie->numGradients; i++)
  {
    prGrad(dbgLevel, FALSE, &ie->gradients[i], i);
  }
  if (includeHeader)
  {
    dbg(dbgLevel, "------------------------------------------------------\n");
  }
}

// Print Interest Cache
void prIntCache(uint32_t dbgLevel, BOOL includeHeader, InterestCache *ic)
{
  uint8_t i = 0;

  if (includeHeader)
  {
    dbg(dbgLevel, "----------------------INTEREST CACHE-------------------\n");
  }

  for (i = 0; i < MAX_INTERESTS; i++)
  {
    if (ic->entries[i].interest.sink != 0 && 
	ic->entries[i].interest.expiration != 0)
    {
      dbg(dbgLevel, "----------------Interest Entry: index = %d\n", i);
      prIntEnt(dbgLevel, FALSE, &ic->entries[i]);
      dbg(dbgLevel, "\n");
    }
  }

  if (includeHeader)
  {
    dbg(dbgLevel, "------------------------------------------------------\n");
  }
}

#else

// Print Attribute
void prAtt(uint32_t dbgLevel, BOOL includeHeader, Attribute *  att, uint8_t num)
{

}

// Print AttributeArray
void prAttArray(uint32_t dbgLevel, BOOL includeHeader, Attribute *  att, uint8_t AttNum)
{

}

// Print Interest Message
void prIntMes(uint32_t dbgLevel, BOOL includeHeader, InterestMessage * m)
{

}

// Print Data Message
void prDataMes(uint32_t dbgLevel, BOOL includeHeader, DataMessage * m)
{

}

// Print Data Cache
void prDataCache(uint32_t dbgLevel, BOOL includeHeader, DataCache * dc)
{

}

// Print Gradient Entry
void prGrad(uint32_t dbgLevel, BOOL includeHeader, InterestGradient * G, int num)
{

}

// Print Interest Entry
void prIntEnt(uint32_t dbgLevel, BOOL includeHeader, InterestEntry * ie)
{

}

// Print Interest Cache
void prIntCache(uint32_t dbgLevel, BOOL includeHeader, InterestCache * ic)
{

}

#endif
