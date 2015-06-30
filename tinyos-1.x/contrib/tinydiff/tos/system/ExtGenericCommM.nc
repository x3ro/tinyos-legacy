module ExtGenericCommM
{
  provides
  {
    interface SendMsg as ProvidedSendMsg[uint8_t id];
    interface ReceiveMsg as ProvidedReceiveMsg[uint8_t id];
  }
  uses
  {
    interface SendMsg as UsedSendMsg[uint8_t id];
    interface ReceiveMsg as UsedReceiveMsg[uint8_t id];
  }
}
implementation
{
  
  #define MAX(a,b) (((a) > (b)) ? (a) : (b))
  #define MIN(a,b) (((a) < (b)) ? (a) : (b))

  command result_t ProvidedSendMsg.send[uint8_t id](uint16_t address, 
                                                   uint8_t length, 
                                                   TOS_MsgPtr msg)
  {
    // including the "saddr" field that we use...
    if (msg->length + 2 > TOSH_DATA_LENGTH)
    {
      dbg(DBG_ERROR, "HEY! msg->length = %d!! can't add 2! no way!\n",
          msg->length);
    }
    msg->length = MIN(msg->length + 2, TOSH_DATA_LENGTH);
    return call UsedSendMsg.send[id](address, 
                                     MIN(length + 2, TOSH_DATA_LENGTH), 
                                     msg);
  }

  event result_t UsedSendMsg.sendDone[uint8_t id](TOS_MsgPtr msg, 
                                                      result_t success)
  {
    return signal ProvidedSendMsg.sendDone[id](msg, success);
  }

  event TOS_MsgPtr UsedReceiveMsg.receive[uint8_t id](TOS_MsgPtr msg)
  {
    if (msg->length - 2 <= 0 )
    {
      dbg(DBG_ERROR, "HEY! msg->length = %d!! can't subtract 2! no way!\n",
          msg->length);
    }
    // excluding the "sadd" field that we use...
    msg->length = MAX(0, msg->length - 2);
    return signal ProvidedReceiveMsg.receive[id](msg);
  }
}
