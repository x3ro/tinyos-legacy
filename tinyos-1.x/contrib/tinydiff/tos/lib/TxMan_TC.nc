configuration TxMan_TC { 
	provides { 
		interface StdControl as Control; 
		interface TxManControl;
		interface Enqueue_T;
		//command result_t enqueueTx[uint8_t id](TOS_MsgPtr msg); 
		//command result_t enqueueTx(TOS_MsgPtr msg); 
	} 
	uses {
		interface BareSendMsg as CommSendMsg;
	}
}
implementation {

	components TxMan_TM, RandomLFSR, RadioCRCPacket as Comm, LedsC as Leds;

	Control = TxMan_TM.StdControl;
	TxManControl = TxMan_TM.TxManControl;
	Enqueue_T = TxMan_TM.Enqueue_T;
	CommSendMsg = TxMan_TM.CommSendMsg;

	TxMan_TM.CommSendMsg -> Comm;

	TxMan_TM.RandomLFSR -> RandomLFSR.Random;

	TxMan_TM.Leds -> Leds;
}
