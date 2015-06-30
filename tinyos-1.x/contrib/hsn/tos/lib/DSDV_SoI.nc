includes WSN;
includes WSN_Messages;
includes WSN_Settings;

configuration DSDV_SoI {
   provides {
      interface StdControl as Control;
      interface Send[uint8_t app];
      interface Receive[uint8_t app];
      interface Intercept[uint8_t app];
      interface SingleHopMsg;  // access to single hop packet decoding
      interface MultiHopMsg; // access to multihop packet decoding
      interface DSDVMsg; // access to DSDV packet decoding
      interface Router;
      interface Settings[uint8_t id];
   }
   uses {
      event result_t radioIdle();
      interface Intercept as SoIPlugin;  // append a list of adjuvant nodes
      interface Piggyback as RupdatePiggyback;
   }
}

implementation {
   components DSDV_Core, 
              DSDV_SoI_Metric as Metric, 
#if ENERGY_METRIC
              EnergyMetric,
#endif
              Adjuvant_Settings,
              DSDV_SoI_PacketForwarder as Forwarder, 
              SingleHopManager, 
              TimerC, 
              RandomGen, 
              LedsC;

   Control = DSDV_Core.Control;
   Send = Forwarder.Send;
   Receive = Forwarder.Receive;
   Intercept = Forwarder.Intercept;
   SingleHopMsg = SingleHopManager.SingleHopMsg;
   MultiHopMsg = Forwarder.MultiHopMsg;
   DSDVMsg = Forwarder.DSDVMsg;
   radioIdle = Forwarder.radioIdle;
   RupdatePiggyback = DSDV_Core.RupdatePiggyback;

   Settings = Metric.Settings;
   Settings[SETTING_ID_DSDV_RUPDATE] = DSDV_Core.Settings;
   Settings[SETTING_ID_DSDV_PKT_FW] = Forwarder.Settings;
   Settings[SETTING_ID_ADJUVANT] = Adjuvant_Settings.Settings;

   SoIPlugin = Metric.SoIPlugin;
   Router = Metric.Router;

   Forwarder.SingleHopControl -> SingleHopManager;
   Forwarder.SingleHopSend -> SingleHopManager.SendMsg[AM_ID_DSDV_SOI];
   Forwarder.SingleHopReceive -> SingleHopManager.PromiscuousReceiveMsg[AM_ID_DSDV_SOI];
   Forwarder.SingleHopPayload -> SingleHopManager.Payload;
   Forwarder.SingleHopMsg -> SingleHopManager;
   Forwarder.Timer -> TimerC.Timer[unique("Timer")];
   Forwarder.RouteLookup -> Metric;
   Forwarder.singleHopRadioIdle <- SingleHopManager.radioIdle;
   Forwarder.packetLost -> SingleHopManager.packetLost;

   DSDV_Core.Random -> RandomGen.Random;
   DSDV_Core.Metric -> Metric;
   DSDV_Core.SendRupdate -> SingleHopManager.SendMsg[AM_ID_DSDV_RUPDATE_SOI];
   DSDV_Core.ReceiveRupdate -> SingleHopManager.ReceiveMsg[AM_ID_DSDV_RUPDATE_SOI];
   DSDV_Core.RupdatePayload -> SingleHopManager.Payload;
   DSDV_Core.SendRupdateReq -> SingleHopManager.SendMsg[AM_ID_DSDV_RUPDATE_REQ];
   DSDV_Core.ReceiveRupdateReq -> SingleHopManager.ReceiveMsg[AM_ID_DSDV_RUPDATE_REQ];
   DSDV_Core.Timer -> TimerC.Timer[unique("Timer")];
   DSDV_Core.SingleHopMsg -> SingleHopManager;
   DSDV_Core.MetricControl -> Metric;
   DSDV_Core.ForwardingControl -> Forwarder;
   DSDV_Core.RadioControl -> SingleHopManager;
   DSDV_Core.Leds -> LedsC;

   // SoI specific stuff
   Metric.SoI_Msg -> Forwarder;
   Metric.SphereControl -> Forwarder;
   Metric.AdjuvantSettings -> Adjuvant_Settings;

#if ENERGY_METRIC
#if SOI_ENERGY_WALLPOWER
   // SoISettings controls both SoI_Metric and EnergyMetric at the same time
   // (enableSoI, enableAdjuvantNode...). If you don't want to a node becomes
   // wall power and SoI adjuvant at the same time, just don't wire this
   // The node would be using energy metric but no one is wall power.
   EnergyMetric.AdjuvantSettings -> Adjuvant_Settings;
#endif
#endif

   DSDV_Core.triggerRouteAdvertisement <- Metric.triggerRouteAdvertisement;
}
