configuration EnergyMetric
{
   provides {
      interface Neighbors;
      interface NeighborAge;
      interface StdControl;
      interface NeighborQuality;
      interface Piggyback;
      interface Settings[uint8_t id];
   }
   uses {
      interface SequenceNumber;
      interface AdjuvantSettings;
   }
}

implementation {
   components
#if SMAC_ENERGY_METRIC
              SMACEnergyMetricM as ActualEnergyMetricM,
#else
              EnergyMetricM as ActualEnergyMetricM,
#endif
              Adjuvant_Settings,
#if DSDV_BI_DIR_QUALITY
              NeighborAttributeAndBiDirQualityList as EnergyNeighborQuality;
#else
              NeighborAttributeAndOutboundQualityList as EnergyNeighborQuality;
#endif

   Neighbors = EnergyNeighborQuality.Neighbors;
   NeighborAge = EnergyNeighborQuality.NeighborAge;
   Settings = EnergyNeighborQuality.Settings;
   SequenceNumber = EnergyNeighborQuality.SequenceNumber;
   ActualEnergyMetricM.AdjuvantSettings = AdjuvantSettings;

   Settings[SETTING_ID_DSDV_METRIC] = ActualEnergyMetricM.MetricSettings;
   Piggyback = ActualEnergyMetricM.Piggyback;
   NeighborQuality = ActualEnergyMetricM.NeighborQuality;
   StdControl = ActualEnergyMetricM.StdControl;

   ActualEnergyMetricM.ActualNeighborQuality -> EnergyNeighborQuality;
   ActualEnergyMetricM.QualityControl -> EnergyNeighborQuality;
   ActualEnergyMetricM.NeighborQualPiggyback -> EnergyNeighborQuality;
   ActualEnergyMetricM.NeighborAttr -> EnergyNeighborQuality;
}
