// Configuration file for OnePhasePull


includes AM;
includes msg_types;
includes OnePhasePull;
configuration DiffTest
{
}
implementation 
{

  components Main, 
	     DiffTestM, 
	     OnePhasePullM, 
	     TxManC, 
	     GenericComm, 
	     TimerC,
	     PotM,
	     LedsC, 
	     NoLeds; 

  Main.StdControl -> TimerC.StdControl;
  Main.StdControl -> DiffTestM.StdControl;
  Main.StdControl -> OnePhasePullM.StdControl;


  Main.StdControl -> GenericComm.Control;
  Main.StdControl -> TxManC.Control;

  DiffTestM.Timer -> TimerC.Timer[unique("Timer")];
  DiffTestM.Subscribe -> OnePhasePullM;
  DiffTestM.Publish -> OnePhasePullM;
  DiffTestM.Pot -> PotM;
  DiffTestM.DiffusionControl -> OnePhasePullM;

  OnePhasePullM.Timer -> TimerC.Timer[unique("Timer")];
  OnePhasePullM.Leds -> LedsC;
  OnePhasePullM.TxManControl -> TxManC.TxManControl;
  OnePhasePullM.TxInterestMsg -> TxManC.Enqueue; 
  OnePhasePullM.TxDataMsg -> TxManC.Enqueue;

  OnePhasePullM.RxInterestMsg -> GenericComm.ReceiveMsg[ESS_OPP_INTEREST];
  OnePhasePullM.RxDataMsg -> GenericComm.ReceiveMsg[ESS_OPP_DATA];

  TxManC.CommSendMsg -> GenericComm.SendMsg;
}












