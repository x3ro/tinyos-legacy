module BaseStationStatusM {
  provides {
    interface IsBaseStation;
    interface StdControl;
  }
}

implementation {
  bool isBaseStation;

  command result_t StdControl.init() {
    isBaseStation = FALSE;

    return SUCCESS;
  }

  command result_t StdControl.start() {return SUCCESS;}

  command result_t StdControl.stop() {return SUCCESS;}

  command result_t IsBaseStation.setBase(bool is_base) {
    isBaseStation = is_base;
    return SUCCESS;
  }

  command bool IsBaseStation.isBase() {
    return isBaseStation;
  }
}
