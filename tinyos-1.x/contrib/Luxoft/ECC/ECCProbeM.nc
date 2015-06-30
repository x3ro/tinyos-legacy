/* 
 * ECC Probing application
 */
#ifndef NHOSTS 
#define NHOSTS 2
#endif

module ECCProbeM
{
  provides 
  {
    interface StdControl;
  }
  uses
  {
    interface StdControl as QueueControl;
    interface StdControl as CommControl;
    interface StdControl as ECCControl;
    interface StdControl as AttrControl;
    interface Timer;
    interface SendMsg;
    interface ReceiveMsg;
    interface Leds;
    interface AttrUse;
  }
}
implementation
{
  TOS_Msg smsg[NHOSTS]; //Message we shall send
  IntMsg* pInt[NHOSTS]; //Part of the message responcible for int
  uint8_t i; //just an index variable
  /*
   * StdControl interface
   */
  command result_t StdControl.init()
  {
    result_t ok, ok1; //operation results
    call AttrControl.init();
    ok = call CommControl.init();
    ok1 = call QueueControl.init();
    for (i = 0; i < NHOSTS; i++)
    {
      memset(smsg + i, 0, sizeof(TOS_Msg));
      pInt[i] = (IntMsg*)smsg[i].data;
    }
    return rcombine(ok, ok1);
  }

  command result_t StdControl.start()
  {
    result_t ok1, ok2, ok3; //operation results
    uint8_t enable = 1; 
    call AttrControl.start();
    ok1 = call CommControl.start();
    ok2 = call QueueControl.start();
    ok3 = call Timer.start(TIMER_REPEAT, 1024);
    call AttrUse.setAttrValue("ack_ena", &enable);
    return rcombine3(ok1, ok2, ok3);
  }

  command result_t StdControl.stop()
  {
    call AttrControl.stop();
    call Timer.stop();
    call QueueControl.stop();
    call CommControl.stop();
    return SUCCESS;
  }
  
  /*
   * SendMsg interface
   */
  event result_t SendMsg.sendDone(TOS_MsgPtr msg, result_t success)
  {
    if (success == SUCCESS)
      call Leds.greenOn();
    else
      call Leds.greenOff();
    return SUCCESS;
  }
  
  /*
   * ReceiveMsg interface
   */
  event TOS_MsgPtr ReceiveMsg.receive(TOS_MsgPtr m)
  {
    dbg(DBG_USR2, "APP: Got message\n");
    if (m->addr == TOS_LOCAL_ADDRESS)
      call Leds.greenToggle();
    else
      call Leds.yellowToggle();
    return m;
  }
  
  /*
   * Timer interface
   */
  event result_t Timer.fired()
  {
    if (TOS_LOCAL_ADDRESS == 0)
    {
      for (i = 0; i < (NHOSTS - 1); i++)
      {
        pInt[i]->val = 0;
        pInt[i]->src = TOS_LOCAL_ADDRESS;
        call SendMsg.send(i + 1, sizeof(IntMsg), smsg + i);
      }
      call SendMsg.send(TOS_BCAST_ADDR, sizeof(IntMsg), smsg);
      call SendMsg.send(TOS_UART_ADDR, sizeof(IntMsg), smsg);
    }
    return SUCCESS;
  }
  
  /*
   * AttrUse interface
   */
  event result_t AttrUse.getAttrDone(char *name, char *resultBuf, 
    SchemaErrorNo errorNo)
  {
    return SUCCESS;
  }
  
  event result_t AttrUse.startAttrDone(uint8_t id)
  {
    return SUCCESS;
  }
}

//EOF
