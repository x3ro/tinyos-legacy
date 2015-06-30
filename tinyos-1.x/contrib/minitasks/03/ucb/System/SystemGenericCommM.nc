
includes Config;
#if defined(RADIO_CC1000)
includes onoff;
#endif

module SystemGenericCommM
{
  provides interface StdControl;
  provides interface SendMsg[ uint8_t am ];
  provides interface ReceiveMsg[ uint8_t am ];
  provides interface RadioSending;

  uses interface StdControl as BottomStdControl;
  uses interface SendMsg as BottomSendMsg[ uint8_t am ];
  uses interface ReceiveMsg as BottomReceiveMsg[ uint8_t am ];
}
implementation
{
  command result_t StdControl.init()
  {
    return call BottomStdControl.init();
  }

  command result_t StdControl.start()
  {
    return call BottomStdControl.start();
  }

  command result_t StdControl.stop()
  {
    return call BottomStdControl.stop();
  }

  command result_t SendMsg.send[ uint8_t am ]( uint16_t address, uint8_t length, TOS_MsgPtr msg )
  {
    signal RadioSending.start();
    return call BottomSendMsg.send[am]( address, length, msg );
  }

  event result_t BottomSendMsg.sendDone[ uint8_t am ]( TOS_MsgPtr msg, result_t success )
  {
    return signal SendMsg.sendDone[am]( msg, success );
  }

  event TOS_MsgPtr BottomReceiveMsg.receive[ uint8_t am ]( TOS_MsgPtr msg )
  {
    // if in low power state and the message isn't an onoff message turning the
    // mote on, then drop the message.

#if defined(RADIO_CC1000)
    if( (G_Config.LowPowerStateEnabled == TRUE)
        && (!((am == AM_ONOFF_MSG) && (msg->data[0] != 0)))
      )
    {
      return msg;
    }
#endif

    // otherwise signal all messages
    return signal ReceiveMsg.receive[am]( msg );
  }


  default event result_t SendMsg.sendDone[ uint8_t am ]( TOS_MsgPtr msg, result_t success )
  {
    return SUCCESS;
  }

  default event TOS_MsgPtr ReceiveMsg.receive[ uint8_t am ]( TOS_MsgPtr msg )
  {
    return msg;
  }

  default event void RadioSending.start() { }
}

