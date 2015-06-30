#include "stdafx.h"
#include <assert.h>
//#include <string.h>
//#include <stdlib.h>
#include "symtable.h"

#define HASH_MULTIPLIER 65599
#define INITIALBUCKETS 509
#define MAXBUCKETS 65521

/* This typedef is here simply because I don't like spelling out (struct
   Binding*) often */
typedef struct Binding *Binding_T;

struct Binding
{
  char *pcKey;
  const void *pvValue;
  Binding_T pbNext;
};


/*****************************************************************************
 * Binding_new() Returns a new Binding_T which makes a copy of the string    *
 * pointed to by pcKey and stores it, and also copies the pvValue pointer    *
 ****************************************************************************/

static Binding_T Binding_new(const char *pcKey, const void *pvValue)
{
  Binding_T pbTempBinding;
  char *pcTempKey;
  
  pbTempBinding = (Binding_T)malloc(sizeof(struct Binding));
  assert(pbTempBinding != NULL);
  
  pcTempKey = (char *)malloc(strlen(pcKey) + 1);
  assert(pcTempKey != NULL);
  
  pbTempBinding->pcKey = strcpy(pcTempKey, pcKey);
  pbTempBinding->pvValue = pvValue;
  pbTempBinding->pbNext = NULL;
  
  return pbTempBinding;
}

/*****************************************************************************
 * Binding_free() is a destructor for pbBinding. Reclaims any memory used by *
 * pbBinding and its copy of the key string (pointed to by pcKey)            *
 ****************************************************************************/

static void Binding_free(Binding_T pbBinding)
{
  free(pbBinding->pcKey);
  free(pbBinding);
}
/*****************************************************************************
 * CSymTable::hash() returns a hopefully unique unsigned int for a given pcKey *
 ****************************************************************************/

unsigned int CSymTable::hash(const char *pcKey)
{
  size_t ui;
  unsigned int uiHash = 0U;
  for (ui = 0U; pcKey[ui] != '\0'; ui++)
    uiHash = uiHash * HASH_MULTIPLIER + pcKey[ui];
  return uiHash;
}

/*****************************************************************************
 * Given the current number of buckets (iPrevBuckets) CSymTable::IncBuckets()  *
 * returns the next number of buckets to be used, returns 0 if somehow the   *
 * current bucket count is off                                               *
 ****************************************************************************/
int CSymTable::incBuckets(int iPrevBuckets)
{
  switch(iPrevBuckets)
    {
    case INITIALBUCKETS: return 1021;
    case 1021: return 2053;
    case 2053: return 4093;
    case 4093: return 8191;
    case 8191: return 16381;
    case 16381: return 32771;
    case 32771: return MAXBUCKETS;
    }
  return 0;
}

/*****************************************************************************
 * CSymTable::expand() is used to dynamically increase the number of buckets *
 * in a CSymTable			                                                 *
 ****************************************************************************/

void CSymTable::expand()
{
  int iExpBuckets, iPosition;
  Binding_T *pbExpList;
  Binding_T pbToMove;
  
  iExpBuckets = incBuckets(iBuckets);
  /*self-check to confirm the bucket count is following the standard
    progression*/
  assert(iExpBuckets != 0);

  pbExpList = (Binding_T *)malloc(iExpBuckets * sizeof(Binding_T));
  assert(pbExpList != NULL);
  
  for(int i = 0; i < iExpBuckets; i++)
    pbExpList[i] = NULL;
  
  for(int i = 0; i < iBuckets; i++)
    {
      pbToMove = pbList[i];
      
      while(pbToMove != NULL)
        {
          iPosition = CSymTable::hash(pbToMove->pcKey) % iExpBuckets;
          pbList[i] = pbToMove->pbNext;
          pbToMove->pbNext = pbExpList[iPosition];
          pbExpList[iPosition] = pbToMove;
          
          pbToMove = pbList[i];
        }
    }
  
  free(pbList);
  iBuckets = iExpBuckets;
  pbList = pbExpList;
}

CSymTable::CSymTable()
{
  iSize = 0;
  iBuckets = INITIALBUCKETS;
  pbList = (Binding_T *)malloc(INITIALBUCKETS * sizeof(Binding_T));
  assert(pbList != NULL);
  
  for(int i = 0; i < INITIALBUCKETS; i++)
    pbList[i] = NULL;
}

CSymTable::~CSymTable()
{
  Binding_T pbWalker, pbTemp;
  
  for(int i = 0; i < iBuckets; i++)
    {
      pbWalker = pbList[i];
      while(pbWalker != NULL)
        {
          pbTemp = pbWalker->pbNext;
          Binding_free(pbWalker);
          pbWalker = pbTemp;
        }
    }
  free(pbList);
}

/*****************************************************************************
 * CSymTable::getLength() returns the number of bindings in a CSymTable.       *
 ****************************************************************************/

int CSymTable::getLength()
{
  return iSize;
}

/*******************************************************************************
 * If the CSymTable already contains a binding with key pcKey CSymTable::put() *
 * will return 0; otherwise, CSymTable::put() will insert a binding consisting *
 * of pcKey and pvValue into the CSymTable and return 1. It is a checked	   *
 * runtime error for pcKey to be NULL							               *
 ******************************************************************************/

bool CSymTable::put(const char *pcKey, const void *pvValue)
{
  Binding_T pbWalker, pbPrev;
  int iPosition;
  
  assert(pcKey != NULL);
  
  iPosition = hash(pcKey) % iBuckets;
  
  pbWalker = pbList[iPosition];
  
  if(pbWalker == NULL)
    {
      pbList[iPosition] = Binding_new(pcKey, pvValue);
      iSize++;
      
      if(iSize > iBuckets && iBuckets < MAXBUCKETS)
          expand();
      return true;
    }
  
  while(pbWalker != NULL)
    {
      if(strcmp(pbWalker->pcKey, pcKey) == 0)
        return false;
     
      pbPrev = pbWalker;
      pbWalker = pbWalker->pbNext;
    }
  
  pbPrev->pbNext = Binding_new(pcKey, pvValue);
  iSize++;

  if(iSize > iBuckets &&
     iBuckets < MAXBUCKETS)
     expand();
  
  return true;
}

/*****************************************************************************
 * If the CSymTable contains a binding with key pcKey, CSymTable::remove()	 *
 * will remove that binding from the CSymTable and return 1; otherwise, it	 *
 * will return 0. It is a checked runtime error for pcKey to be NULL		 *
 ****************************************************************************/

bool CSymTable::remove(const char *pcKey)
{
  Binding_T pbWalker, pbPrev;
  int iPosition;
  
  assert(pcKey != NULL);
  
  iPosition = CSymTable::hash(pcKey) % iBuckets;
  
  pbWalker = pbList[iPosition];
  pbPrev = NULL;
  
  while(pbWalker != NULL)
    {
      if(strcmp(pbWalker->pcKey, pcKey) == 0)
        {
          if(pbPrev == NULL)
            pbList[iPosition] = pbWalker->pbNext;
          else
            pbPrev->pbNext = pbWalker->pbNext;
          Binding_free(pbWalker);
          iSize--;
          return true;
        }
      pbPrev = pbWalker;
      pbWalker = pbWalker->pbNext;
    }
  
  return false;
}

/*****************************************************************************
 * If the CSymTable contains a binding with key pcKey, CSymTable::contains() *
 * will return 1; otherwise it will return 0. It is a checked runtime error  *
 * for pcKey to be NULL														 *
 ****************************************************************************/

bool CSymTable::contains(const char *pcKey)
{
  Binding_T pbWalker;

  assert(pcKey != NULL);
  
  pbWalker = pbList[hash(pcKey) % iBuckets];

  while(pbWalker != NULL)
    {
      if(strcmp(pbWalker->pcKey, pcKey) == 0)
        return true;
      pbWalker = pbWalker->pbNext;
    }
  
  return false;
}

/*****************************************************************************
 * If the CSymTable contains a binding with key pcKey, CSymTable::get() will *
 * return the value of that binding; otherwise it will return NULL. It is a  *
 * checked runtime error for pcKey to be NULL								 *
 ****************************************************************************/

void *CSymTable::get(const char *pcKey)
{
  Binding_T pbWalker;

  assert(pcKey != NULL);
  
  pbWalker = pbList[hash(pcKey) % iBuckets];
  while(pbWalker != NULL)
    {
      if(strcmp(pbWalker->pcKey, pcKey) == 0)
        return (void *)pbWalker->pvValue;
      pbWalker = pbWalker->pbNext;
    }
  
  return NULL;
}

/*****************************************************************************
 * CSymTable::map will apply the function pfApply to every binding in the	 *
 * CSymTable, passing pvExtra as an extra parameter to pfApply. It is a      *
 * checked runtime error for pfApply to be NULL								 *
 ****************************************************************************/

void CSymTable::map(void (*pfApply)(const char *pcKey, void *pvValue,
					void *pvExtra), const void *pvExtra)
{
  Binding_T pbWalker;
  
  assert(pfApply != NULL);
  
  for(int i = 0; i < iBuckets; i++)
    {
      pbWalker = pbList[i];
      while(pbWalker != NULL)
        {
          (*pfApply)(pbWalker->pcKey, (void *)pbWalker->pvValue,
                     (void *)pvExtra);
          pbWalker = pbWalker->pbNext;
        }
    }
}