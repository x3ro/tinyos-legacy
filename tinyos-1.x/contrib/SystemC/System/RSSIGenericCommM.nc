
includes DefineCC1000;

module RSSIGenericCommM
{
  provides interface StdControl;
  provides interface SendMsg[ uint8_t am ];
  provides interface ReceiveMsg[ uint8_t am ];

  uses interface StdControl as BottomStdControl;
  uses interface SendMsg as BottomSendMsg[ uint8_t am ];
  uses interface ReceiveMsg as BottomReceiveMsg[ uint8_t am ];

#if defined(RADIO_CC1000)
  uses interface RadioCoordinator;
  uses interface ADC;
#endif
}
implementation
{
  enum
  {
    WORST_RSSI_VALUE = 65535u,
  };

  uint16_t m_rssi_sum;
  uint16_t m_rssi_count;

  command result_t StdControl.init()
  {
    m_rssi_sum = 0;
    m_rssi_count = 0;
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

  
#if defined(RADIO_CC1000)
  async event void RadioCoordinator.startSymbol(uint8_t bitsPerBlock, 
						  uint8_t offset, 
						  TOS_MsgPtr msgBuff)
  {
    m_rssi_sum = 0;
    m_rssi_count = 0;
    call ADC.getData();
  }

  async event void RadioCoordinator.byte( TOS_MsgPtr msg, uint8_t count )
  {
    call ADC.getData();
  }

  async event void RadioCoordinator.blockTimer()
  {}


  async event result_t ADC.dataReady( uint16_t value )
  {
    m_rssi_sum += value;
    m_rssi_count++;
    return SUCCESS;
  }
#endif
  
  command result_t SendMsg.send[ uint8_t am ]( uint16_t addr, uint8_t length, TOS_MsgPtr msg )
  {
    return call BottomSendMsg.send[ am ]( addr, length, msg );
  }

  event result_t BottomSendMsg.sendDone[ uint8_t am ]( TOS_MsgPtr msg, result_t success )
  {
    return signal SendMsg.sendDone[ am ]( msg, success );
  }

  event TOS_MsgPtr BottomReceiveMsg.receive[ uint8_t am ]( TOS_MsgPtr msg )
  {
    uint16_t rssi_count = m_rssi_count;
    uint16_t rssi_sum = m_rssi_sum;
    if( rssi_count > 0 )
      msg->strength = rssi_sum / rssi_count;
    else
      msg->strength = WORST_RSSI_VALUE;
    return signal ReceiveMsg.receive[ am ]( msg );
  }


  default event result_t SendMsg.sendDone[ uint8_t am ]( TOS_MsgPtr msg, result_t success )
  {
    return SUCCESS;
  }

  default event TOS_MsgPtr ReceiveMsg.receive[ uint8_t am ]( TOS_MsgPtr msg )
  {
    return msg;
  }
}

