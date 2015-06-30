configuration EnergyModel
{
   provides {
      interface StdControl as Control;
      command uint16_t EnergyConsumed();
      interface Settings[uint8_t id];
   }
   uses {
      interface Intercept;
      interface MultiHopMsg;
#ifdef SMAC_ENERGY
      interface MACPerformance;
#endif
   }
}
implementation {
   components TimerC,
              SingleHopManagerM,
#ifdef SMAC_ENERGY
              SMACEnergyM as ActualEnergyModelM;
#else
#ifdef ENERGY_METRIC
              NeighborAttributeAndBiDirQualityList as NeighborQualityList,
#else
              NeighborBiDirQualityList as NeighborQualityList,
#endif
#ifdef SMAC_ENERGY_MODEL
              SMACEnergyModelM as ActualEnergyModelM;
#else
              EnergyModelM as ActualEnergyModelM;
#endif
              
#endif
   ActualEnergyModelM.Control = Control;
   ActualEnergyModelM.EnergyConsumed = EnergyConsumed;
   ActualEnergyModelM.Intercept = Intercept;
   ActualEnergyModelM.MultiHopMsg = MultiHopMsg;

#ifdef SMAC_ENERGY
  ActualEnergyModelM.MACPerformance = MACPerformance;
#else
   ActualEnergyModelM.Timer -> TimerC.Timer[unique("Timer")];
   ActualEnergyModelM.Neighbors -> NeighborQualityList.Neighbors;
   ActualEnergyModelM.NetStat -> SingleHopManagerM.NetStat;
#endif

   Settings[SETTING_ID_ENERGY_MEASURE] = ActualEnergyModelM.Settings;
}
