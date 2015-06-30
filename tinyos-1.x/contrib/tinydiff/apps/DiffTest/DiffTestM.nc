includes OnePhasePull;
module DiffTestM 
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
    interface Pot;
  }

}
implementation
{

  #include "OPPLib/Debug.c"
  PublicationHandle pubHandle;
  int8_t startDelay;
  uint16_t secondCounter;
  SubscriptionHandle subHandle;

  enum {
    DATA_INTERVAL = 15  // 60 // once every minute
  };

  task void startupTask()
  {
    Attribute a;

    dbg(DBG_USR1, "Starting up... TOS_LOCAL_ADDRESS: = %d\n", TOS_LOCAL_ADDRESS);
    if (TOS_LOCAL_ADDRESS == 1) // for NIDO only!
    {
      //result_t result = FAIL;

      a.key = TEMP;
      a.op = EQ_ANY;
      a.value = 40;
      subHandle = call Subscribe.subscribe(&a, 1);
      dbg(DBG_USR1, "DiffTestM: subscribing for TEMP. subHandle = %d\n", subHandle);

      /*
      result = call Subscribe.unsubscribe(subHandle);
      dbg(DBG_USR1, "DiffTestM: unsubscribe of handle %d %s\n",
	  subHandle, (result == SUCCESS ? "SUCCEEEDED" : "FAILED"));

      a.key = PRESSURE;
      a.op = EQ_ANY;
      a.value = 55;
      subHandle = call Subscribe.subscribe(&a, 1);
      dbg(DBG_USR1, "DiffTestM: subscribing for PRESSURE. subHandle = %d\n", subHandle);

      a.key = ESS_LOAD_KEY;
      a.op = EQ_ANY;
      a.value = 55;
      subHandle = call Subscribe.subscribe(&a, 1);
      dbg(DBG_USR1, "DiffTestM: subscribing for PRESSURE. subHandle = %d\n", subHandle);
      */
    }
    else if (TOS_LOCAL_ADDRESS != 0)
    {
      // dummy values... not used for now...
      a.key = TEMP;
      a.op = IS;
      a.value = 66;

      dbg(DBG_USR1, "DiffTestM: invoking Publish.publish.\n");
      pubHandle = call Publish.publish(&a, 1);
    }
    startDelay = -1;
  }
    
  command result_t StdControl.init()
  {
    startDelay = 5;
    subHandle = 0;
    secondCounter = DATA_INTERVAL;
    call Pot.init(60);
    call Pot.set(60);
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
    //dbg(DBG_USR1, "DiffTestM: StdControl.start: starting timer..\n");
    // fires every second
    call Timer.start(TIMER_REPEAT, 1000);
    //addGradientOverrides();
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
    static int timerCount = 0; 

    timerCount++;

    if (--startDelay > 0)
    {
      return SUCCESS;
    }
    else if (startDelay == 0)
    {
      post startupTask();
      startDelay = -1;
    }
    else if (TOS_LOCAL_ADDRESS != 1 && TOS_LOCAL_ADDRESS != 0)
    {
      if (--secondCounter <= 0)
      {
	static BOOL turn = 0;

	if (turn == 0)
	{
	  for (i = 0; i < 5; i++)
	  {
	    a[i].key = TEMP;
	    a[i].op = IS;
	    a[i].value = TOS_LOCAL_ADDRESS * 10 + i;
	  }

	  num = MAX_ATT > 5 ? 5 : MAX_ATT; 
	  call Publish.sendData(pubHandle, a, num); 
	  /*
	  dbg(DBG_USR1, "DiffTestM: Timer.fired: sending data...\n");
	  prAttArray(DBG_USR1, TRUE, a, num);
	  */

	}
	else if (turn == 1)
	{
	  for (i = 0; i < 4; i++)
	  {
	    a[i].key = PRESSURE;
	    a[i].op = IS;
	    a[i].value = TOS_LOCAL_ADDRESS * 10 + 4 + i;
	  }

	  num = MAX_ATT > 4 ? 4 : MAX_ATT; 
	  call Publish.sendData(pubHandle, a, num); 
	}
	else 
	{
	  for (i = 0; i < 4; i++)
	  {
	    a[i].key = ESS_LOAD_KEY;
	    a[i].op = IS;
	    a[i].value = TOS_LOCAL_ADDRESS * 10 + 8 + i;
	  }

	  num = MAX_ATT > 4 ? 4 : MAX_ATT; 
	  call Publish.sendData(pubHandle, a, num); 
	}

	//send only temperature for this test..
	//turn = (turn + 1) % 3;

	secondCounter = DATA_INTERVAL;
      }
    }

    if (timerCount >= 15)
    {
      //removeGradientOverrides();
    }
    
    return SUCCESS;
  }
  
}
