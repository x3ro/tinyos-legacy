includes MgmtQuery;

configuration MgmtAttrsC {
  provides {
    interface StdControl;
    interface MgmtAttrRetrieve;
    interface MgmtAttr[uint16_t id];
  }
}
implementation {
  
  components MgmtAttrsM;

  StdControl = MgmtAttrsM;

  MgmtAttr = MgmtAttrsM;
  MgmtAttrRetrieve = MgmtAttrsM;
}
