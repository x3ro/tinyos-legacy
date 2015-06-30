configuration BaseStationStatus {
  provides {
    interface StdControl;
    interface IsBaseStation;
  }
}

implementation {
  components BaseStationStatusM;

  StdControl = BaseStationStatusM.StdControl;
  IsBaseStation = BaseStationStatusM.IsBaseStation;
}
