/* Lin Gu <lingu@cs.virginia.edu>
 * Date last modified:  12/2/2002
 */

includes MSG_POOL;

module MsgPool {
  provides interface Pool;
}

implementation
{

  // extern short TOS_LOCAL_ADDRESS;

  // #include "AM_CONFIRM.h"

#define MPL_POOL_SIZE 0X18

#define MPL_BUSY 0X1

  typedef struct {
    Cell msg;
    char tag;
  } MsgBuf;

  MsgBuf pool[MPL_POOL_SIZE];
  int nFree;
  PoolInfo poolinfoMe;

  command result_t Pool.init() {
    int i;

    dbg(DBG_AM, "MSG_POOL: INIT: pool @ %x\n", pool);

    for (i = 0; i < MPL_POOL_SIZE; i++) {
      pool[i].tag = 0;
    }

    nFree = MPL_POOL_SIZE;

    // debug info
    poolinfoMe.lNumAlloc = poolinfoMe.lNumFree = poolinfoMe.nOccupied = 0;

    return SUCCESS;
  }

  command char Pool.alloc()
    {
      return 0;
    }


  command CellPtr Pool.copy(CellPtr pMsg)
    {
      int i;
      char *pSrc = (char *)pMsg, *pDest;

      dbg(DBG_AM, 
	  "MSG_POOL: copy packet: originally @ %p, 9th char %x\n", 
	  pMsg, pSrc[8]);
#ifdef DEBUGGING
#endif

      for (i=0; i<MPL_POOL_SIZE; i++)
	{
	  if (!(pool[i].tag & MPL_BUSY))
	    {
	      // copy packet bytes
	      int j;

	      pool[i].tag |= MPL_BUSY;	  
	      for (pDest  = (char *)(&((pool[i]).msg)), j=0; 
		   j<sizeof(TOS_Msg); 
		   j++, pSrc++, pDest++)
		{
		  *pDest = *pSrc;
		} // for
	      nFree--;

#ifdef DEBUGGING
	      dbg(DBG_AM, "MSG_POOL: copy packet: to: %x, 9th char %x,total free slots %d\n", 
		  &(pool[i].msg),
		  ((char *)(&(pool[i].msg)))[8],nFree);
#endif
          
	      poolinfoMe.lNumAlloc++;

	      return &((pool[i]).msg);
	    }
	} // for

      dbg(DBG_AM, "MSG_POOL: copy_packet: no slot. first tag %x\n", pool[0].tag);

      return 0;
    }

  MsgBuf *findMsgBuf(CellPtr pMsg)
    {
      int i;
  
#ifdef DEBUGGING
      dbg(DBG_AM, "MSG_POOL: FindMsgBuf: begin for pMsg: %x\n", pMsg);
#endif

      for (i=0; i<MPL_POOL_SIZE; i++)
	{
	  if ((&(pool[i].msg) == pMsg) && pool[i].tag & MPL_BUSY)
	    {
#ifdef DEBUGGING
	      dbg(DBG_AM, "MSG_POOL: findMsgBuf: found: i=%d\n", i);
#endif

	      return &(pool[i]);
	    } // if
	} // for

      return 0;
    }

  command char Pool.free(CellPtr pMsg)
    {
      MsgBuf *p;

      if ((p = findMsgBuf(pMsg)))
	{
	  p->tag &= ~(MPL_BUSY);
	  nFree++;

#ifdef DEBUGGING
	  dbg(DBG_AM, "MSG_POOL: FREE_MEM: a slot %x freed, tag: %x,total freel slots %d\n",pMsg,p->tag,nFree);
#endif
      
	  poolinfoMe.lNumFree++;

	  return 1;
	}
      else{
	dbg(DBG_AM, "MSG_POOL: FREE_MEM: can't find out such buffer %p,FindResult %x\n",pMsg,p);
	return 0;
      }
    }

  command PoolInfoPtr Pool.getInfo(){
    poolinfoMe.nOccupied = MPL_POOL_SIZE - nFree;
    return &poolinfoMe;
  }
}
