//$Id: DripSendC.nc,v 1.3 2005/07/16 01:29:47 gtolle Exp $

includes DripSend;

generic configuration DripSendC(uint8_t channel) {
  provides interface StdControl;
  provides interface Send;
  provides interface SendMsg;
  provides interface Receive;
}
implementation {

  components new DripSendM();

  components DripC;
  components DripStateC;
  components GroupManagerC;
  components LedsC;

  StdControl = DripSendM;
  StdControl = DripC;

  Send = DripSendM;
  SendMsg = DripSendM;
  Receive = DripSendM;
  
  DripSendM.DripReceive -> DripC.Receive[channel];
  DripSendM.Drip -> DripC.Drip[channel];
  DripC.DripState[channel] -> DripStateC.DripState[unique("DripState")];

  DripSendM.GroupManager -> GroupManagerC;
  DripSendM.Leds -> LedsC;
}
