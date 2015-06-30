////////////////////////////////////////////////////////////////////////////
//
// CENS
//
// Contents: 
//
// Purpose: 
//
////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////

includes EssDefs;

module EssTestM 
{
  provides 
  {
    interface StdControl;
  }
  uses
  {
    interface EssComm;
    interface Timer;
    interface Leds;
    interface Filter as InterestFilter;
    interface Subscribe;
    interface CC1000Control;
    interface Random;
  }
}
implementation
{
  #include "OPPLib/Debug.c"

  int8_t startDelay;
  int16_t secondCounter;
  SubscriptionHandle subHandle;
  DiffMsg myDiffMsg;
  BOOL myDiffMsgBusy;

  enum 
  {
    MAX_SINK_ID = 2, // Max id of sinks we are using...
    DATA_INTERVAL = 3, // every 5 seconds
  };
  
  task void startupTask();

  command result_t StdControl.init()
  {
    startDelay = 5;
    subHandle = 0;
    secondCounter = DATA_INTERVAL;
    myDiffMsgBusy = FALSE;
    
    call Random.init();
    return SUCCESS;
  }

  command result_t StdControl.start()
  {
    result_t result = FAIL;

    //dbg(DBG_USR1, "EssTestM: StdControl.start: starting timer..\n");
    // fires every second
    call Timer.start(TIMER_REPEAT, 1000);

    result = call CC1000Control.SetRFPower(3);
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

  task void startupTask()
  {
    Attribute a[MAX_ATT];
    result_t result;

    dbg(DBG_USR1, "Starting up... TOS_LOCAL_ADDRESS: = %d\n", TOS_LOCAL_ADDRESS);
    // the "0" check is for NIDO
    if (TOS_LOCAL_ADDRESS != 0 && TOS_LOCAL_ADDRESS <= MAX_SINK_ID) 
    {
      // accept data meant only for me... 
      a[0].key = ESS_CLUSTERHEAD_KEY;
      a[0].op = EQ;
      a[0].value = TOS_LOCAL_ADDRESS;

      // any temperature...
      a[1].key = TEMP;
      a[1].op = EQ_ANY;
      a[1].value = 40;

      subHandle = call Subscribe.subscribe(a, 2);
      dbg(DBG_USR1, "EssTestM: subscribing for TEMP. subHandle = %d\n", 
	  subHandle);

      a[0].key = CLASS;
      a[0].op = EQ;
      a[0].value = INTEREST;

      result = call InterestFilter.addFilter(a, 1);
      dbg(DBG_USR1, "EssTestM: addFilter %s\n",
	  result == SUCCESS ? "SUCCEEDED" : "FAILED");
      
    }

    startDelay = -1;
  }
  
  task void interestHandlerTask()
  {
    result_t retVal = FAIL;
    Attribute *pAttr = NULL;
    uint8_t numAttrs = 0;
    uint8_t i = 0;
    BOOL loadAttrFound = FALSE;

    retVal = getAttrs(&myDiffMsg, &pAttr, &numAttrs);

    if (FAIL == retVal || NULL == pAttr || 0 == numAttrs)
    {
      dbg(DBG_ERROR, "EssTestM: receiveMatchingMsg: getAttrs failed or "
	  "returned junk!\n");
    }

    // see if there's already a load key...
    loadAttrFound = FALSE;
    for (i = 0; i < numAttrs; i++)
    {
      if (ESS_LOAD_KEY == pAttr[i].key)
      {
	loadAttrFound = TRUE;
      }
    }

    if (FALSE == loadAttrFound)
    // if not, add it...
    {
      // if there are more attributes than there's place for load key, discard
      // the last attribute
      if (numAttrs >= MAX_ATT)
      {
	dbg(DBG_ERROR, "EssTestM: receiveMatchingMsg: too many attrs: %d!\n",
	    numAttrs);

	numAttrs = MAX_ATT - 1; // as though there's space for one more...
      }

      // in any case, add load_factor as the numAttrs+1th (or last, as the case 
      // may be) attribute
      pAttr[numAttrs].key = ESS_LOAD_KEY;
      pAttr[numAttrs].op = IS;
      pAttr[numAttrs].value = call Random.rand() % 10; // for this experiment only

      dbg(DBG_USR1, "EssTestM: interestHandlerTask: load key = %d\n",
          pAttr[numAttrs].value);
      numAttrs++;

      if (FAIL == setNumAttrs(&myDiffMsg, numAttrs))
      {
	dbg(DBG_ERROR, "EssTestM: setNumAttrs: FAILED!\n");
      }
    }

    retVal = call InterestFilter.sendMessage(&myDiffMsg, 
					      F_PRIORITY_SEND_TO_NEXT);

    dbg(DBG_USR1, "EssTestM: interestHandlerTask: sending message %s\n",
	(retVal == SUCCESS ? "SUCCEEDED." : "FAILED!"));

    myDiffMsgBusy = FALSE;
  }

  // Mohan's note: we have to manipulate the interest message... we have no 
  // choice... since it is this filter that adds in the load factor attr
  event result_t InterestFilter.receiveMatchingMsg(DiffMsgPtr diffMsg)
  {
    // this filter is supposed to run only on sinks...
    if (TOS_LOCAL_ADDRESS > MAX_SINK_ID || TOS_LOCAL_ADDRESS == 0)
    {
      return FAIL;
    }
    
    if (NULL == diffMsg) 
    {
      dbg(DBG_ERROR, "EssTest: receiveMatchingMsg: passed a NULL msg\n");
      return FAIL;
    }

    if (TRUE == myDiffMsgBusy)
    {
      // it is important to FAIL here because we want OPP to continue
      // forwarding the message to subsequent filters...
      return FAIL;
    }

    myDiffMsgBusy = TRUE;

    dbg(DBG_USR1, "EssTest: receiveMatchingMsg: got Interest message\n");
    memcpy(&myDiffMsg, diffMsg, sizeof(DiffMsg));
    
    post interestHandlerTask();

    return SUCCESS;
  }

  event result_t Subscribe.receiveMatchingData(SubscriptionHandle handle,
					       AttributePtr attributes,
					       uint8_t numAttrs)
  {
    dbg(DBG_USR1, "Subscribe.receiveMatchingData GOT DATA: %d attributes; "
	"handle = %d\n", numAttrs, handle);
    prAttArray(DBG_USR1, TRUE, attributes, numAttrs);

    return SUCCESS;
  }

  task void dataSendTask()
  {
    int i = 0;
    int num = 0;
    result_t retVal = FAIL;
    uint16_t a[5];

    dbg(DBG_USR3, "EssTestM: dataSendTask: invoked\n");
    // -2 because of (1) "CLASS IS DATA" and (2) "CLUSTERHEAD IS clId"
    // attributes
    num = MAX_ATT - 2 > 5 ? 5 : MAX_ATT - 2; 

    for (i = 0; i < num; i++)
    {
      a[i] = TOS_LOCAL_ADDRESS * 10 + i;
    }


    retVal = call EssComm.send(TEMP, a, num);

    dbg(DBG_USR1, "EssTestM: dataSendTask(): EssComm.send %s\n",
	(retVal == SUCCESS ? "SUCCEEDED" : "FAILED"));
  }

  event result_t Timer.fired()
  {
    // TODO: remove hard-coded stuff...

    // to introduce initial startup delay -- for Nido
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

    // after startup delay, send data periodically
    if (TOS_LOCAL_ADDRESS != 0 && TOS_LOCAL_ADDRESS > MAX_SINK_ID)
    {
      if (--secondCounter <= 0)
      {
	post dataSendTask();

	secondCounter = DATA_INTERVAL;
      }
    }

    return SUCCESS;
  }


}

