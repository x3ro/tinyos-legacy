#ifndef MSG_POOL_H
#define MSG_POOL_H
typedef struct 	{
  long lNumAlloc, lNumFree, nOccupied;
} PoolInfo;

typedef PoolInfo *PoolInfoPtr;

#endif
