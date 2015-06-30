configuration RssiLocationHoodManagerC {
  provides {
    interface StdControl;
  }
}

implementation {
  
  components RssiLocationHoodManagerM as Manager, RssiLocationHoodC as Hood, TimerC;

  StdControl=Manager;
  Manager.RssiLocationRefl -> Hood.RssiLocationRefl;
  Manager.HoodManager -> Hood;
  Manager.Hood -> Hood;

}

