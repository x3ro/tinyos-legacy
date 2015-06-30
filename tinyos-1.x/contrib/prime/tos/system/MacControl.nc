/*									tab:4
 * MAC layer control
 *
 * Authors: Lin Gu
 * Date:    6/18/2003
 */


module MacControl
{
  provides {
    interface NetworkControl;
  }
  uses {
    interface SendMsg as SendControlMsg;
  }
}

implementation
{
#include "NetworkControlMessages.h"

  TOS_Msg msgControl;

  result_t setNetProperty(char cFunc, 
			  uint16_t maStart1,
			  uint16_t maEnd1,
			  uint16_t maStart2,
			  uint16_t maEnd2,
			  uint16_t maStart3,
			  uint16_t maEnd3,
			  uint16_t maStart4,
			  uint16_t maEnd4)
    {
      ControlPkt *pcp = (ControlPkt *)(msgControl.data);
      
      switch (cFunc)
	{
	case NC_DISABLE_UPPER_PORTION:
	  pcp->maStart1 = maStart1;
	  pcp->maSender = TOS_LOCAL_ADDRESS;
	  pcp->nOp = NC_DISABLE_UPPER_PORTION;
	  return call SendControlMsg.send(TOS_LOCAL_ADDRESS, 18, &msgControl);

	  break;

	case NC_DISABLE4:
	  pcp->maStart1 = maStart1;
	  pcp->maEnd1 = maEnd1;
	  pcp->maStart2 = maStart2;
	  pcp->maEnd2 = maEnd2;
	  pcp->maStart3 = maStart3;
	  pcp->maEnd3 = maEnd3;
	  pcp->maStart4 = maStart4;
	  pcp->maEnd4 = maEnd4;
	  pcp->maSender = TOS_LOCAL_ADDRESS;
	  pcp->nOp = NC_DISABLE4;
	  return call SendControlMsg.send(TOS_LOCAL_ADDRESS, 27, &msgControl);

	  break;

	case NC_ENABLE_UPPER_PORTION:
	  pcp->nOp = NC_ENABLE_UPPER_PORTION;
	  return call SendControlMsg.send(TOS_LOCAL_ADDRESS, 18, &msgControl);
	
	default:
	  ;
	}
    }

  command result_t NetworkControl.set(char cFunc, uint16_t addr) {
    setNetProperty(cFunc, addr, addr, 0, 0, 0, 0, 0, 0);

    return SUCCESS;
  }

  command result_t NetworkControl.disable()
    {
      dbg(DBG_AM, "MacControl: disabling Mac\n");

      return setNetProperty(NC_DISABLE_UPPER_PORTION, 
			    TOS_LOCAL_ADDRESS, TOS_LOCAL_ADDRESS+80, 
			    0, 0,
			    0, 0, 
			    0, 0);
    }

  command result_t NetworkControl.disable4(uint16_t maStart1,
			  uint16_t maEnd1,
			  uint16_t maStart2,
			  uint16_t maEnd2,
			  uint16_t maStart3,
			  uint16_t maEnd3,
			  uint16_t maStart4,
			  uint16_t maEnd4)
    {
      dbg(DBG_AM, "MacControl: disable4\n");

      return setNetProperty(NC_DISABLE4, 
			    maStart1, maEnd1,
			    maStart2, maEnd2,
			    maStart3, maEnd3,
			    maStart4, maEnd4);
    } // disable4

  event result_t SendControlMsg.sendDone(TOS_MsgPtr pmsg, result_t r)
    {
      return SUCCESS;
    }
}

