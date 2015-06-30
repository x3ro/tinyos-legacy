/* Author: Matt Welsh
 */

abstract configuration GenericCommAC(int handler_id) {
  provides {
    interface StdControl as Control;
    interface CommControl;

    interface SendVarLenPacket as UARTSendRawBytes;
    
    interface SendMsg;
    interface ReceiveMsg;

    // How many packets were received in the past second
    command uint16_t activity();

  }
  uses {
    // signaled after every send completion for components which wish to
    // retry failed sends
    event result_t sendDone();
  }
}
implementation
{
  // CRCPacket should be multiply instantiable. As it is, I have to use
  // RadioCRCPacket for the radio, and UARTNoCRCPacket for the UART to
  // avoid conflicting components of CRCPacket.
  components AMHandler(handler_id) as AM,
    RadioCRCPacket as RadioPacket, 
    UARTNoCRCPacket as UARTPacket,
    NoCRCPacket as UARTRawBytes,
    NoLeds as Leds, InjectMsg,
    AbstractTimerC(), ClockC;

  UARTSendRawBytes = UARTRawBytes.SendVarLenPacket;
  
  Control = AM.Control;
  CommControl = AM.CommControl;
  SendMsg = AM.SendMsg;
  ReceiveMsg = AM.ReceiveMsg;
  sendDone = AM.sendDone;

  activity = AM.activity;
  
  AM.ActivityTimer -> AbstractTimerC;
  
  AM.UARTControl -> UARTPacket.Control;
  AM.UARTSend -> UARTPacket.Send;
  AM.UARTReceive -> UARTPacket.Receive;
  
  AM.RadioControl -> RadioPacket.Control;
  AM.RadioSend -> RadioPacket.Send;
  AM.RadioReceive -> RadioPacket.Receive;
  //AM.RadioReceive -> InjectMsg; // for nido

  AM.Leds -> Leds;
}
