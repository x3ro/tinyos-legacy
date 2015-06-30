

/*
 * Main CC1000 Configuration
 * This configuration provides access to the CC1000 radio stack
 * @author David Moss
 *
 */

includes AM;

configuration CC1000RadioC {
  provides {
    interface StdControl;
    interface BareSendMsg as Send;
    interface ReceiveMsg as Receive;
    interface LowPowerListening;
    interface Packet;
    interface CC1000Control;
    interface PacketAcknowledgements;
    interface MacControl;
    interface CsmaBackoff;
    interface CsmaControl;
    interface RadioCoordinator as RadioReceiveCoordinator;
    interface RadioCoordinator as RadioSendCoordinator;
    interface RadioTimeStamping;
  }
}

implementation {
  components CC1000SendReceiveC, CC1000ControlC;
  components CC1000CsmaC, CC1000RssiC;
  components RandomC;
  
  StdControl = CC1000SendReceiveC;
  StdControl = CC1000ControlC;
  StdControl = CC1000RssiC;
  StdControl = CC1000CsmaC;
  StdControl = RandomC;
  
  Send = CC1000SendReceiveC;
  Receive = CC1000SendReceiveC;
  Packet = CC1000SendReceiveC;
  PacketAcknowledgements = CC1000SendReceiveC;
  MacControl = CC1000SendReceiveC;
  RadioReceiveCoordinator = CC1000SendReceiveC.RadioReceiveCoordinator;
  RadioSendCoordinator = CC1000SendReceiveC.RadioSendCoordinator;
  CsmaBackoff = CC1000CsmaC;
  CsmaControl = CC1000CsmaC;
  RadioTimeStamping = CC1000SendReceiveC;
  
  LowPowerListening = CC1000CsmaC;
  
  CC1000Control = CC1000ControlC;
}






