includes Ext_AM;
includes NeighborStore;
module NeighborFilterM {
  provides {
    interface StdControl;
    command result_t configureThresholds(uint16_t low, uint16_t high);
    // filtered comm. interfaces
    interface ReceiveMsg as FilteredReceiveMsg[uint8_t type];
    interface Enqueue as FilteredEnqueue;
  }
  uses {
    // "raw" comm. interfaces..
    interface ReceiveMsg as UnfilteredReceiveMsg[uint8_t type];
    interface Enqueue as UnfilteredEnqueue;
    // interfaces to access NeighborStore
    interface ReadNeighborStore;
    interface WriteNeighborStore;
  }
}
implementation
{
  // NOTE: need to set this to appropriate values... so, field experience
  // necessary...
  enum {
    DEFAULT_LOW_WATER = 300,
    DEFAULT_HIGH_WATER = 325 
  };

  uint16_t lowWater;
  uint16_t highWater;

  
  command result_t StdControl.init()
  {
    lowWater = DEFAULT_LOW_WATER;
    highWater = DEFAULT_HIGH_WATER;
    return SUCCESS;
  }
  
  command result_t StdControl.start()
  {
    return SUCCESS;
  }
  
  command result_t StdControl.stop()
  {
    return SUCCESS;
  }
  
  // set thresholds...
  // NOTE: thresholds are maintained as 1000 times the actual value in
  // order to store and manipulate them in ints
  command result_t configureThresholds(uint16_t low, uint16_t high)
  {
    // sanity check...
    if (low > high)
    {
      lowWater = DEFAULT_LOW_WATER;
      highWater = DEFAULT_HIGH_WATER;
      return SUCCESS;
    }

    lowWater = low;
    highWater = high;
    return SUCCESS;
  }

  event TOS_MsgPtr UnfilteredReceiveMsg.receive[uint8_t type](TOS_MsgPtr pTosMsg)
  {
    // get neighbor data from the neighbor store 
    // if "bad" link, discard, if not, allow
    uint16_t inLoss = 0, outLoss = 0, bidirLoss = 0;
    result_t retVal = SUCCESS;
    uint16_t linkGoodness = NS_GOOD_LINK;
    Ext_TOS_MsgPtr msg = NULL;
    
    // Use the Ext_TOS_Msg overlay
    msg = (Ext_TOS_MsgPtr)pTosMsg;
    
    if (0 == msg->saddr)
    {
      goto passUpMsg;
    }
    
    retVal = call ReadNeighborStore.getNeighborMetric16(msg->saddr, 
							NS_16BIT_IN_LOSS, 
							&inLoss);

    // NOTE: if we cannot find a matching entry in the NeighborStore, we allow
    // the packet to go through... this is because, upon addition of a new
    // neighbor, it is assumed to be a GOOD link until proven otherwise
    if (retVal == FAIL)
    {
      dbg(DBG_ERROR, "NeighborFilterM: passing up from node %d: unable to read "
	  "IN loss\n", msg->saddr);
      goto passUpMsg;
    }

    retVal = call ReadNeighborStore.getNeighborMetric16(msg->saddr, 
							NS_16BIT_OUT_LOSS, 
							&outLoss);
    if (retVal == FAIL)
    {
      dbg(DBG_ERROR, "NeighborFilterM: passing up from node %d: unable to read"
	  " OUT loss\n", msg->addr);
      goto passUpMsg;
    }

    bidirLoss = inLoss + ((uint32_t)(1000 - inLoss) * (uint32_t)outLoss) / 
      (uint32_t)1000;

    retVal = call ReadNeighborStore.getNeighborMetric16(msg->saddr, 
							NS_16BIT_LINK_GOODNESS, 
							&linkGoodness);
    if (retVal == SUCCESS)
    {
      // implementation of hysterisis... if in between the low and high
      // water marks... decide on action based on previous states... 
      if (bidirLoss < highWater && bidirLoss > lowWater)
      {
	if (linkGoodness == NS_GOOD_LINK)
	{
	  dbg(DBG_USR3, "NeighborFilter: passing up from %d: low %d < bidir: %d "
	      "< high: %d; GOOD_LINK\n", msg->saddr, lowWater, bidirLoss, 
	      highWater);
	  goto passUpMsg;
	}
	else
	{
	  // drop packet
	  dbg(DBG_USR3, "NeighborFilter: DROPPING from %d: low %d < bidir: %d "
	      "< high: %d; BAD_LINK\n", msg->saddr, lowWater, bidirLoss, 
	      highWater);
	  goto receiveDropMsg;
	}
      }
    }
    
    // if highWater or lowWater is hit, change state... to bad or good link
    // quality respectively
    if (bidirLoss >= highWater)
    {
      call WriteNeighborStore.setNeighborMetric16(msg->saddr, 
						  NS_16BIT_LINK_GOODNESS, 
						  NS_BAD_LINK);

      // drop message
      dbg(DBG_USR3, "NeighborFilter: DROPPING from node %d: bidirLoss: "
	  "%d >= high: %d\n", msg->saddr, bidirLoss, highWater);
      goto receiveDropMsg;
    }

    if (bidirLoss <= lowWater)
    {
      call WriteNeighborStore.setNeighborMetric16(msg->saddr, 
						  NS_16BIT_LINK_GOODNESS,
						  NS_GOOD_LINK);

      dbg(DBG_USR3, "NeighborFilter: passing up from %d: bidirLoss: %d < low: "
	  "%d\n", msg->saddr, bidirLoss, lowWater);
      // fall through...
    }

passUpMsg: 
    return signal FilteredReceiveMsg.receive[type]((TOS_MsgPtr)msg);

receiveDropMsg:
      return (TOS_MsgPtr)msg;
  }
  
  // Default handler for the filtered ReceiveMsg interface... this is
  // because if there are interface instances which have not been bound to
  // by applications, and event are signaled on those interfaces, there
  // would be no one to hanlde it if there were no default handlers... 
  default event TOS_MsgPtr FilteredReceiveMsg.receive[uint8_t type]
    (TOS_MsgPtr msg)
  {
    return msg;
  }

  // For sending, the idea of multiple interfaces is not that important or
  // relevant... since the message anyway carries the AM message type in
  // it... so, a parameterized interface for just setting the message type
  // (as is done in GenericComm.SendMsg) is not quite necessary...
  command result_t FilteredEnqueue.enqueue(Ext_TOS_MsgPtr pTosMsg)
  {
    // get neighbor data from the neighbor store 
    // if "bad" link, discard, if not, allow
    uint16_t inLoss = 0, outLoss = 0, bidirLoss = 0;
    result_t retVal = SUCCESS;
    uint16_t linkGoodness = NS_GOOD_LINK;
    Ext_TOS_MsgPtr msg = NULL;
    
    msg = pTosMsg;

    // typical case...
    if (msg->addr == TOS_BCAST_ADDR)
    {
      goto passDownMsg;
    }
    
    retVal = call ReadNeighborStore.getNeighborMetric16(msg->addr, 
							NS_16BIT_IN_LOSS, 
							&inLoss);

    if (retVal == FAIL)
    {
      goto passDownMsg;
    }

    retVal = call ReadNeighborStore.getNeighborMetric16(msg->addr, 
							NS_16BIT_OUT_LOSS, 
							&outLoss);
    if (retVal == FAIL)
    {
      goto passDownMsg;
    }

    bidirLoss = inLoss + ((uint32_t)(1000 - inLoss) * (uint32_t)outLoss) / 
      (uint32_t)1000;

    retVal = call ReadNeighborStore.getNeighborMetric16(msg->addr, 
							NS_16BIT_LINK_GOODNESS, 
							&linkGoodness);
    if (retVal == SUCCESS)
    {
      // implementation of hysterisis... if in between the low and high
      // water marks... decide on action based on previous states... 
      if (bidirLoss < highWater && bidirLoss > lowWater)
      {
	if (linkGoodness == NS_GOOD_LINK)
	{
	  goto passDownMsg;
	}
	else
	{
	  // drop packet
	  dbg(DBG_USR3, "NeighborFilterM: enqueue: DROPPING(1) packet from %d\n",
	      msg->saddr);
	  return FAIL;
	}
      }
    }
    
    // if highWater or lowWater is hit, change state... to bad or good link
    // quality respectively
    if (bidirLoss >= highWater)
    {
      call WriteNeighborStore.setNeighborMetric16(msg->addr, 
						  NS_16BIT_LINK_GOODNESS, 
						  NS_BAD_LINK);

      // drop message
      dbg(DBG_USR3, "NeighborFilterM: enqueue: DROPPING(2) packet from %d\n",
	  msg->saddr);
      return FAIL; 
    }

    if (bidirLoss <= lowWater)
    {
      call WriteNeighborStore.setNeighborMetric16(msg->addr, 
						  NS_16BIT_LINK_GOODNESS, 
						  NS_GOOD_LINK);

      // fall through...
    }

passDownMsg: 
      return call UnfilteredEnqueue.enqueue(msg);

  }

  
}
