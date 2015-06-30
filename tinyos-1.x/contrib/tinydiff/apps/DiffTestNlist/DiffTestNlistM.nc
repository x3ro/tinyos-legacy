includes OnePhasePull;
includes DiffMsg;
module DiffTestNlistM 
{
  provides 
  {
    interface StdControl;
  }
  uses
  {
    interface Publish;
    interface Subscribe;
    interface DiffusionControl;
    interface Timer;
    interface CC1000Control;
    interface Filter as Filter1;
    interface Filter as Filter2;
    interface Leds;
  }

}
implementation
{

  #include "OPPLib/Debug.c"
  PublicationHandle pubHandle;
  int8_t startDelay;
  int16_t secondCounter;
  SubscriptionHandle subHandle;
  Ext_TOS_Msg myExtTosMsg;

  enum {
    DATA_INTERVAL = 4//10  // 60 // once every minute
  };

  task void startupTask()
  {
    Attribute a[MAX_ATT];
    result_t result = FAIL;

    dbg(DBG_USR1, "Starting up... TOS_LOCAL_ADDRESS: = %d\n", TOS_LOCAL_ADDRESS);
    if (TOS_LOCAL_ADDRESS == 1) // for NIDO only!
    {
      //result_t result = FAIL;

      a[0].key = TEMP;
      a[0].op = EQ_ANY;
      a[0].value = 40;
      subHandle = call Subscribe.subscribe(a, 1);
      dbg(DBG_USR1, "DiffTestNlistM: subscribing for TEMP. subHandle = %d\n", 
	  subHandle);

      // ----------------------
      a[0].key = CLASS;
      a[0].op = EQ;
      a[0].value = INTEREST;
      result = call Filter1.addFilter(a, 1);

      dbg(DBG_USR1, "DiffTestNlistM: addFilter1 %s\n",
	  result == SUCCESS ? "SUCCEEDED" : "FAILED");
    }
    else if (TOS_LOCAL_ADDRESS != 0)
    {
      // dummy values... not used for now...
      a[0].key = TEMP;
      a[0].op = IS;
      a[0].value = 66;

      pubHandle = call Publish.publish(a, 1);
      dbg(DBG_USR1, "DiffTestNlistM: invoking Publish.publish; pubHandle = %d.\n",
	  pubHandle);

      // ----------------------
      a[0].key = CLASS;
      a[0].op = EQ;
      a[0].value = DATA;
      a[1].key = TEMP;
      a[1].op = LT;
      a[1].value = 40;
      result = call Filter1.addFilter(a, 2);

      dbg(DBG_USR1, "DiffTestNlistM: addFilter1 %s\n",
	  result == SUCCESS ? "SUCCEEDED" : "FAILED");

      // ----------------------
      a[0].key = CLASS;
      a[0].op = EQ;
      a[0].value = DATA;
      a[1].key = TEMP;
      a[1].op = GE;
      a[1].value = 40;
      result = call Filter2.addFilter(a, 2);

      dbg(DBG_USR1, "DiffTestNlistM: addFilter2 %s\n",
	  result == SUCCESS ? "SUCCEEDED" : "FAILED");
    }
    startDelay = -1;
  }
    
  command result_t StdControl.init()
  {
    startDelay = 5;
    subHandle = 0;
    secondCounter = DATA_INTERVAL;

    return SUCCESS;
  }

  void addGradientOverrides()
  {
    if (TOS_LOCAL_ADDRESS == 2)
    {
      Attribute a;
      uint16_t gradient = NULL_NODE_ID;
      result_t result = FAIL;
      
      a.key = TEMP;
      a.op = LT;
      a.value = 71;
  
      gradient = 3;

      result = call DiffusionControl.addGradientOverride(&a, 1, &gradient, 1);
      dbg(DBG_USR1, "addGradientOverrides: addition of gradient %s\n",
	  (result == SUCCESS ? "SUCCEEDED" : "FAILED"));
    }
  }
  
  task void forwarderTask1()
  {
    call Filter1.sendMessage(&myExtTosMsg, F_PRIORITY_SEND_TO_NEXT);
  }

  task void forwarderTask2()
  {
    call Filter2.sendMessage(&myExtTosMsg, F_PRIORITY_SEND_TO_NEXT);
  }

  event result_t Filter1.receiveMatchingMsg(DiffMsgPtr msg)
  {
    InterestMessage *intMsg = NULL;
    DataMessage *dataMsg = NULL;

    dbg(DBG_USR1, "DiffTestNlistM: Filter1.receiveMatchingMsg: got packet:\n"); 

    if (msg->type == ESS_OPP_DATA)
    {
      dataMsg = (DataMessage *)msg->data;
      prDataMes(DBG_USR1, TRUE, dataMsg);
    }
    else if (msg->type == ESS_OPP_INTEREST)
    {
      intMsg = (InterestMessage *)msg->data;
      prIntMes(DBG_USR1, TRUE, intMsg);
    }

    memcpy((char *)&myExtTosMsg, (char *)msg, sizeof(Ext_TOS_Msg));
    post forwarderTask1();

    return SUCCESS;
  }
  
  event result_t Filter2.receiveMatchingMsg(DiffMsgPtr msg)
  {
    InterestMessage *intMsg = NULL;
    DataMessage *dataMsg = NULL;

    dbg(DBG_USR1, "DiffTestNlistM: Filter2.receiveMatchingMsg: got packet:\n"); 

    if (msg->type == ESS_OPP_DATA)
    {
      dataMsg = (DataMessage *)msg->data;
      prDataMes(DBG_USR1, TRUE, dataMsg);
    }
    else if (msg->type == ESS_OPP_INTEREST)
    {
      intMsg = (InterestMessage *)msg->data;
      prIntMes(DBG_USR1, TRUE, intMsg);
    }

    memcpy((char *)&myExtTosMsg, (char *)msg, sizeof(Ext_TOS_Msg));
    post forwarderTask2();

    return SUCCESS;
  }

  void removeGradientOverrides()
  {
    if (TOS_LOCAL_ADDRESS == 2)
    {
      Attribute a;
      result_t result = FAIL;
      
      a.key = TEMP;
      a.op = LT;
      a.value = 91;
  
      result = call DiffusionControl.removeGradientOverride(&a, 1);
      dbg(DBG_USR1, "removeGradientOverrides: removal of gradient %s\n",
	  (result == SUCCESS ? "SUCCEEDED" : "FAILED"));
    }
  }

    
  command result_t StdControl.start()
  {
    result_t result = FAIL;

    //dbg(DBG_USR1, "DiffTestNlistM: StdControl.start: starting timer..\n");
    // fires every second
    call Timer.start(TIMER_REPEAT, 1000);
    //addGradientOverrides();

    result = call CC1000Control.SetRFPower(1);
    if (result == SUCCESS)
    {
      call Leds.greenOn();
    }
    else
    {
      call Leds.redOn();
    }

    return SUCCESS;
  }
  command result_t StdControl.stop()
  {
    call Timer.stop();
    return SUCCESS;
  }

  event result_t Subscribe.receiveMatchingData(SubscriptionHandle handle,
					       AttributePtr attributes,
					       uint8_t numAttrs)
  {
    dbg(DBG_USR1, "Subscribe.receiveMatchingData returned %d attributes; "
	"handle = %d\n", numAttrs, handle);
    prAttArray(DBG_USR1, TRUE, attributes, numAttrs);
    return SUCCESS;
  }

  event result_t Timer.fired()
  {
    // TODO: remove hard-coded stuff...
    Attribute a[5];
    int i = 0;
    int num = 0;

    if (startDelay > 0)
    {
      startDelay--;
      return SUCCESS;
    }
    else if (startDelay == 0)
    {
      post startupTask();
      // so that we don't post startupTask anymore...
      startDelay--;
    }

    if (TOS_LOCAL_ADDRESS != 1 && TOS_LOCAL_ADDRESS != 0)
    {
      if (--secondCounter <= 0)
      {
	for (i = 0; i < 5; i++)
	{
	  a[i].key = TEMP;
	  a[i].op = IS;
	  a[i].value = TOS_LOCAL_ADDRESS * 10 + i;
	}

	num = MAX_ATT - 1 > 5 ? 5 : MAX_ATT - 1; 
	call Publish.sendData(pubHandle, a, num); 
	/*
	dbg(DBG_USR1, "DiffTestNlistM: Timer.fired: sending data...\n");
	prAttArray(DBG_USR1, TRUE, a, num);
	*/

	secondCounter = DATA_INTERVAL;
      }
    }

    
    return SUCCESS;
  }
  
}
