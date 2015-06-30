includes WSN;
includes WSN_Messages;
includes WSN_Settings;
includes AODV;

configuration AODV {
   provides {
      interface StdControl as Control;
      interface Send[uint8_t app];
      interface Receive[uint8_t app];
      interface Intercept[uint8_t app];
      interface SendMHopMsg[uint8_t app];
      interface SingleHopMsg;  // access to single hop packet decoding
      interface MultiHopMsg; // access to multihop packet decoding
      interface AODVMsg; // access to AODV packet decoding
      //      interface ReactiveRouter;
//      interface Settings[uint8_t id];
   }
   uses {
      event result_t radioIdle();
   }
}

implementation {

components AODV_Core, AODV_PacketForwarder,
              SingleHopManager, RandomGen, TimerC,LedsC;

   Control = AODV_Core.Control;
   Send = AODV_PacketForwarder.Send;
   SendMHopMsg = AODV_PacketForwarder.SendMHopMsg;
   Receive = AODV_PacketForwarder.Receive;
   Intercept = AODV_PacketForwarder.Intercept;
   SingleHopMsg = SingleHopManager.SingleHopMsg;
   MultiHopMsg = AODV_PacketForwarder.MultiHopMsg;
   AODVMsg = AODV_PacketForwarder.AODVMsg;
   radioIdle = AODV_PacketForwarder.radioIdle;
   //  ReactiveRouter = AODV_Core.ReactiveRouter;


   AODV_PacketForwarder.ReactiveRouter -> AODV_Core.ReactiveRouter;
   AODV_PacketForwarder.SingleHopControl -> SingleHopManager;
   AODV_PacketForwarder.SingleHopSend -> SingleHopManager.SendMsg[AM_ID_AODV];
   AODV_PacketForwarder.SingleHopReceive -> SingleHopManager.PromiscuousReceiveMsg[AM_ID_AODV];
   AODV_PacketForwarder.SingleHopPayload -> SingleHopManager.Payload;
   AODV_PacketForwarder.SingleHopMsg -> SingleHopManager;
   AODV_PacketForwarder.Timer -> TimerC.Timer[unique("Timer")];
   AODV_PacketForwarder.RouteLookup -> AODV_Core.RouteLookup;

   AODV_PacketForwarder.singleHopRadioIdle <- SingleHopManager.radioIdle;
   AODV_PacketForwarder.packetLost -> SingleHopManager.packetLost;
   AODV_PacketForwarder.RouteError -> AODV_Core.RouteError;
   AODV_Core.Random -> RandomGen.Random;

   AODV_Core.SendRreq -> SingleHopManager.SendMsg[AM_ID_AODV_RREQ_HOPS];
   AODV_Core.ReceiveRreq -> SingleHopManager.ReceiveMsg[AM_ID_AODV_RREQ_HOPS];
   AODV_Core.RreqPayload -> SingleHopManager.Payload;

   AODV_Core.SendRreply -> SingleHopManager.SendMsg[AM_ID_AODV_RREPLY_HOPS];
   AODV_Core.ReceiveRreply -> SingleHopManager.ReceiveMsg[AM_ID_AODV_RREPLY_HOPS];
   AODV_Core.RreplyPayload -> SingleHopManager.Payload;

   AODV_Core.SendRerr -> SingleHopManager.SendMsg[AM_ID_AODV_RERR_HOPS];
   AODV_Core.ReceiveRerr -> SingleHopManager.ReceiveMsg[AM_ID_AODV_RERR_HOPS];
   AODV_Core.RerrPayload -> SingleHopManager.Payload;


   AODV_Core.Timer -> TimerC.Timer[unique("Timer")];
   AODV_Core.SingleHopMsg -> SingleHopManager;
   
   

   AODV_Core.ForwardingControl -> AODV_PacketForwarder;
   AODV_Core.RadioControl -> SingleHopManager;
   AODV_Core.Leds -> LedsC;
}
