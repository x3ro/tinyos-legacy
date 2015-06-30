//$Id: GrouperC.nc,v 1.4 2005/06/14 18:10:10 gtolle Exp $

includes Grouper;
includes Ident;

/**
 * This component provides the ability to remotely set group
 * membership for nodes.
 *
 * @author Gilman Tolle
 */
configuration GrouperC {
  provides interface StdControl;
}

implementation {

  components 
    GrouperM,
    GroupManagerC,
    DripC, 
    DripStateC,
    GenericComm,
    LedsC;

#if defined(PLATFORM_TELOSB)
  components DS2411C;
#endif

  StdControl = GrouperM;

  GrouperM.ReceiveMsg -> GenericComm.ReceiveMsg[AM_GROUPERCMDMSG];
  GrouperM.Receive -> DripC.Receive[AM_GROUPERCMDMSG];
  GrouperM.Drip -> DripC.Drip[AM_GROUPERCMDMSG];
  DripC.DripState[AM_GROUPERCMDMSG] -> DripStateC.DripState[unique("DripState")];

#if defined(PLATFORM_TELOSB)
  GrouperM.DS2411 -> DS2411C;
#endif

  GrouperM.GroupManager -> GroupManagerC;
  GrouperM.Leds -> LedsC;
}
