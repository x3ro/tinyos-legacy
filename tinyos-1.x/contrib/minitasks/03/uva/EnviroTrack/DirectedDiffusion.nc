includes DirectedDiffusion;

configuration DirectedDiffusion {

  provides {
    interface StdControl;
    interface RoutingSendByMobileID		;
    interface RoutingDDReceiveDataMsg	;
    interface Interest					;

  }

}
implementation {

    components DirectedDiffusionM, TimerC, LedsC, GenericComm, RandomLFSR;


	//Jun08
    components LocalM;
    DirectedDiffusionM.Local ->		LocalM.Local;
 
 
    DirectedDiffusionM.CommControl      ->GenericComm;
    DirectedDiffusionM.Timer -> TimerC.Timer[unique("Timer")];
    DirectedDiffusionM.Random        ->RandomLFSR.Random;
    DirectedDiffusionM.Leds -> LedsC;
    DirectedDiffusionM.SendMsg->GenericComm.SendMsg[AM_DD_MSG];
    DirectedDiffusionM.ReceiveMsg->GenericComm.ReceiveMsg[AM_DD_MSG];
//    DirectedDiffusionM.SendMsgByID->GenericComm.SendMsg[AM_DD_MSG];
//    DirectedDiffusionM.SendMsgByEvent->GenericComm.SendMsg[AM_DD_MSG];
    
    StdControl				= DirectedDiffusionM;
    RoutingSendByMobileID	= DirectedDiffusionM;
    RoutingDDReceiveDataMsg	= DirectedDiffusionM;
    Interest				= DirectedDiffusionM;

}

