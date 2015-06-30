/*
 * This configuration provides a packet forwarding module that sandwiches 
 * DSDV_SoI_PacketForwarderM between DSDV_PacketForwarder and the single hop 
 * layer
 */
configuration DSDV_SoI_PacketForwarder {
   provides {
      interface StdControl as Control;
      interface Send[uint8_t app];
      interface Receive[uint8_t app];
      interface Intercept[uint8_t app];
      interface DSDVMsg;
      interface MultiHopMsg;
      event result_t singleHopRadioIdle();
      interface Settings;
      interface SoI_Msg;
      interface SphereControl;
      interface PacketAck;
   }
   uses {
      interface StdControl as SingleHopControl;
      interface SendMsg as SingleHopSend;
      interface ReceiveMsg as SingleHopReceive;
      interface Payload as SingleHopPayload;
      interface RoutingControl;
      interface Timer;
      interface RouteLookup;
      interface SingleHopMsg;
      event result_t radioIdle();
      command void packetLost();
   }
}

implementation {
   components DSDV_PacketForwarder, DSDV_SoI_PacketForwarderM, LedsC;

   // hook up all uses clauses
   Control = DSDV_PacketForwarder.Control;
   Receive = DSDV_PacketForwarder.Receive;
   Intercept = DSDV_PacketForwarder.Intercept;
   DSDVMsg = DSDV_PacketForwarder.DSDVMsg;
   MultiHopMsg = DSDV_PacketForwarder.MultiHopMsg;
   singleHopRadioIdle = DSDV_PacketForwarder.singleHopRadioIdle;
   Settings = DSDV_PacketForwarder.Settings;
   packetLost = DSDV_PacketForwarder.packetLost;

   // hook up all provides clauses
   SingleHopControl = DSDV_PacketForwarder.SingleHopControl;
   SingleHopReceive = DSDV_PacketForwarder.SingleHopReceive;
   RoutingControl = DSDV_PacketForwarder.RoutingControl;
   Timer = DSDV_PacketForwarder.Timer;
   RouteLookup = DSDV_PacketForwarder.RouteLookup;
   SingleHopMsg = DSDV_PacketForwarder.SingleHopMsg;
   radioIdle = DSDV_PacketForwarder.radioIdle;
   PacketAck = DSDV_PacketForwarder.PacketAck;

   // hook up SoI module
   SoI_Msg = DSDV_SoI_PacketForwarderM.SoI_Msg;
   SphereControl = DSDV_SoI_PacketForwarderM.SphereControl;

   DSDV_PacketForwarder -> DSDV_SoI_PacketForwarderM.Payload;
   SingleHopPayload = DSDV_SoI_PacketForwarderM.SingleHopPayload;

   Send = DSDV_SoI_PacketForwarderM.Send;
   DSDV_SoI_PacketForwarderM.SendToMultiHop -> DSDV_PacketForwarder.Send;
   DSDV_PacketForwarder.SingleHopSend ->
             DSDV_SoI_PacketForwarderM.SendFromMultiHop;
   SingleHopSend = DSDV_SoI_PacketForwarderM.SingleHopSend;
   DSDV_PacketForwarder.Leds -> LedsC;

}
