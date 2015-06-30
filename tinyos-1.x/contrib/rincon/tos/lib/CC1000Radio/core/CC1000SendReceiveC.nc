
/**
 * CC1000 Send/Receive Configuration
 * Implements a byte radio to transmit and receive packets
 *
 * @author David Moss
 */

includes AM;

configuration CC1000SendReceiveC {
  provides {
    interface StdControl;
    interface BareSendMsg as Send;
    interface ReceiveMsg as Receive;
    interface ByteRadio;
    interface Packet;
    interface PacketAcknowledgements;
    interface MacControl;
    interface RadioCoordinator as RadioSendCoordinator;
    interface RadioCoordinator as RadioReceiveCoordinator;
    interface RadioTimeStamping;
  }
}

implementation {
  components CC1000SendReceiveM, CC1000ControlC, CC1000RssiC, HplSpiC;
  components PacketM;
  
  StdControl = CC1000SendReceiveM;
  Send = CC1000SendReceiveM;
  Receive = CC1000SendReceiveM;
  ByteRadio = CC1000SendReceiveM;
  PacketAcknowledgements = CC1000SendReceiveM;
  MacControl = CC1000SendReceiveM;
  RadioSendCoordinator = CC1000SendReceiveM.RadioSendCoordinator;
  RadioReceiveCoordinator = CC1000SendReceiveM.RadioReceiveCoordinator;
  RadioTimeStamping = CC1000SendReceiveM;
  
  Packet = PacketM;
  
  CC1000SendReceiveM.CC1000Control -> CC1000ControlC;
  CC1000SendReceiveM.SpiByteFifo -> HplSpiC;
  CC1000SendReceiveM.RssiRx -> CC1000RssiC.Rssi[unique("Rssi")];

}

