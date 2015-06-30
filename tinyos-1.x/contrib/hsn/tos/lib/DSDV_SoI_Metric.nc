includes WSN_Settings;

/*
 * Warning!  Don't use this module with NeighborQualityList.  The quality
 * scale is different from NeighborBiDirQualityList and
 * NeighborOutboundQualityList.
 */
configuration DSDV_SoI_Metric {
   provides {
      interface StdControl;
      interface RouteUpdate;
      interface RouteLookup;
      interface Router;
      interface Settings[uint8_t id];
   }
   uses {
      interface SoI_Msg;
      interface SphereControl;
      interface AdjuvantSettings;
      interface Intercept as SoIPlugin;  // append a list of adjuvant nodes
      event void triggerRouteAdvertisement();
   }
}
implementation {
   components DSDV_SoI_MetricM,
              SingleHopManager, // same as Queuing
#if ENERGY_METRIC
              EnergyMetric as NeighborQuality,
#else
              ReliabilityMetric as NeighborQuality,
#endif
              LedsC;

   DSDV_SoI_MetricM.StdControl = StdControl;
   DSDV_SoI_MetricM.RouteUpdate = RouteUpdate;
   DSDV_SoI_MetricM.RouteLookup = RouteLookup;
   DSDV_SoI_MetricM.SoIPlugin = SoIPlugin;
   //DSDV_SoI_MetricM.SoIPluginPayload = SoIPluginPayload;
   DSDV_SoI_MetricM.Router = Router;

   Settings = NeighborQuality.Settings;
   SingleHopManager.SequenceNumber <- NeighborQuality;

   DSDV_SoI_MetricM.QualityControl -> NeighborQuality;
   DSDV_SoI_MetricM.NeighborQuality -> NeighborQuality;
   DSDV_SoI_MetricM.Neighbors -> NeighborQuality;
   DSDV_SoI_MetricM.Piggyback -> NeighborQuality;

   DSDV_SoI_MetricM.SoI_Msg = SoI_Msg;
   DSDV_SoI_MetricM.SphereControl = SphereControl;
   DSDV_SoI_MetricM.AdjuvantSettings = AdjuvantSettings;

   DSDV_SoI_MetricM.Leds -> LedsC;

   triggerRouteAdvertisement = DSDV_SoI_MetricM.triggerRouteAdvertisement;
}
