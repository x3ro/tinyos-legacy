includes NeighborStore;
includes BeaconPacket;
module NeighborTestM {
  provides {
    interface StdControl;
  }
  uses {
    interface Enqueue;
    interface ReceiveMsg;
    interface Timer;
    interface Leds;
    interface StdControl as TimerStdControl;
    //command result_t configureThresholds(uint16_t low, uint16_t high);
  }
}
implementation
{
  #include "msg_types.h"

  Ext_TOS_Msg recvPacket;
  Ext_TOS_Msg sendPacket;
  Ext_TOS_MsgPtr msgPtr;
  uint16_t neighbors[MAX_NUM_NEIGHBORS];
  int i;
  int interval;

  command result_t StdControl.init()
  {
    dbg(DBG_USR1, "NeighborTestM: initializing... TOS_LOCAL_ADDRESS = %d\n", TOS_LOCAL_ADDRESS);
    interval = 5;
    msgPtr = &recvPacket;
    memset((char *)neighbors, 0, MAX_NUM_NEIGHBORS * sizeof(uint16_t));
    return SUCCESS;
  } 

  command result_t StdControl.start()
  {
    //call TimerStdControl.start();
    call Timer.start(TIMER_REPEAT, 5000);
    return SUCCESS;
  } 

  command result_t StdControl.stop()
  {
    //call TimerStdControl.stop();
    call Timer.stop();
    return SUCCESS;
  } 

  task void sendTask()
  {
    uint8_t count;

    sendPacket.addr = TOS_BCAST_ADDR;
    sendPacket.saddr = TOS_LOCAL_ADDRESS;
    // TODO: introduce enum 
    sendPacket.type = MSG_NEIGHBOR_TEST;
    sendPacket.group = 0x7d;
    sendPacket.length = NB_MAX_PKT_SIZE;

    memset(sendPacket.data, 0, NB_MAX_PKT_SIZE);
    // this code will break for larger number of neighbors...
    for (i = 0, count = 0; i < MAX_NUM_NEIGHBORS; i++)
    {
      if (neighbors[i] != 0)
      {
	// fill up on only what you can...
	if (2 * count + 2 >= NB_MAX_PKT_SIZE)
	{
	  break;
	}
	memcpy(&sendPacket.data[2 * count + 1], (char *)&neighbors[i], 2);
	count++;
      }
    }
    sendPacket.data[0] = count; // byte 1 is count of neighbors

    dbg(DBG_TEMP, "NeighborTestM: sendPacket: sending packet\n");
    call Enqueue.enqueue(&sendPacket);

    if (--interval == 0)
    {
      memset((char *)neighbors, 0, MAX_NUM_NEIGHBORS * sizeof(uint16_t));
      interval = 5;
    }
  }

  event TOS_MsgPtr ReceiveMsg.receive(TOS_MsgPtr pTosMsg)
  {
    uint8_t freeIndex;
    Ext_TOS_MsgPtr msg = NULL;

    msg = (Ext_TOS_MsgPtr)pTosMsg;

    call Leds.yellowToggle();

    if (msg->saddr == 0)
    {
      return (TOS_MsgPtr)msg;
    }

    for (i = 0, freeIndex = MAX_NUM_NEIGHBORS; i < MAX_NUM_NEIGHBORS; i++)
    {
      if (neighbors[i] == 0 && freeIndex == MAX_NUM_NEIGHBORS)
      {
	freeIndex = i;
      }
      if (neighbors[i] == msg->saddr)
      {
	break;
      }
    }
    if (i == MAX_NUM_NEIGHBORS && freeIndex != MAX_NUM_NEIGHBORS)
    {
      neighbors[freeIndex] = msg->saddr;
    }
    
    dbg(DBG_TEMP, "NeighborTestM: receive: received packet!\n");
    return (TOS_MsgPtr)msg;
  }
  
  event result_t Timer.fired()
  {
    post sendTask();      
    return SUCCESS;
  }
}
