// Configuration file for OnePhasePull

// NOTE:  This file is not being used... since it does not buy us much...
// the application using OnePhasePull has to do these wirings anyway... 

includes Definition;
includes AM;
includes msg_types;

configuration OnePhasePull {
}

implementation {

  components Main, 
	     OnePhasePullM, 
	     TxManC, 
	     GenericComm, 
	     TimerC,
	     LedsC; 

  Main.StdControl -> LedsC;
  Main.StdControl -> OnePhasePullM.StdControl;

  OnePhasePullM.Timer -> TimerC.Timer[unique("Timer")];

  OnePhasePullM.Leds -> LedsC;

  OnePhasePullM.TxManControl -> TxManC.TxManControl;

  OnePhasePullM.TxInterestMsg -> TxManC.Enqueue; 
  OnePhasePullM.TxDataMsg -> TxManC.Enqueue;

  OnePhasePullM.RxInterestMsg -> GenericComm.ReceiveMsg[ESS_OPP_INTEREST];
  OnePhasePullM.RxDataMsg -> GenericComm.ReceiveMsg[ESS_OPP_DATA];

  TxManC.CommSendMsg -> GenericComm.SendMsg;
}












