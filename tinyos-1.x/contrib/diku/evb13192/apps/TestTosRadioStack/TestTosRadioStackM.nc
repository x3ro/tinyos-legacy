
module TestTosRadioStackM
{
	provides {
		interface StdControl;
	}
	uses {
		//interface SendMsg as Send;
		//interface ReceiveMsg as Receive;
		interface BareSendMsg as Send;
		interface ReceiveMsg as Receive;
		interface mc13192Control as RadioControl;
		interface mc13192CCA as RadioCCA;
		interface mc13192PowerManagement as RadioPowerMng;
		interface Timer;
		interface Leds;
		interface ConsoleOutput as ConsoleOut;
	}
}
implementation
{
	// Variables for the mac comm
	// rx_packet_t rx_packet;
	// char rx_buf[20] = "receive buffer";
	//#define BUFLEN 20
	uint8_t bufLen = 29;
	TOS_Msg packet;
	char tx_buf[52] = "abcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyz";
	uint8_t paValue = 16;	
	bool dozing = FALSE;
		
	result_t transmitPacket();
	task void edTask();
	task void dozeTask();
	task void hibernateTask();
 
	/* **********************************************************************
	 * Setup/Init code
	 * *********************************************************************/

	/* Init */
	command result_t StdControl.init()
	{
		packet.addr = 1;
		packet.length = bufLen;
		memcpy(packet.data, tx_buf, bufLen);
		return SUCCESS;
	}

	/* start */
	command result_t StdControl.start()
	{
		//transmitPacket();
		call RadioControl.setChannel(0);
		call RadioControl.setTimerPrescale(5);
		bufLen = 0;
/*		call ConsoleOut.print("Chip Set Mask Id is: 0x");
		call ConsoleOut.printHex(call RadioControl.getChipMaskSetId());
		call ConsoleOut.print("\n");
		call ConsoleOut.print("Chip Version Id is: 0x");
		call ConsoleOut.printHex(call RadioControl.getChipVersion());
		call ConsoleOut.print("\n");
		call ConsoleOut.print("Chip Manufacturer Id is: 0x");
		call ConsoleOut.printHex(call RadioControl.getChipManufacturerId());
		call ConsoleOut.print("\n");*/
		
		transmitPacket();
		//call Timer.start(TIMER_ONE_SHOT, 1000);
		//post edTask();
		return SUCCESS;
	}

	/* stop - never called */
	command result_t StdControl.stop()
	{
		//call Leds.redOff();
		return SUCCESS;
	}

	/* **********************************************************************
	 * Timer/radio related code
	 * *********************************************************************/
	
	result_t transmitPacket()
	{
		/*call ConsoleOut.print("Packet send: ");
		call ConsoleOut.printStr(packet.data, packet.length);
		call ConsoleOut.print("\n");*/
		//call ConsoleOut.print("Sending packet\n");
		call Send.send(&packet);
		return SUCCESS;
	}

	event result_t Send.sendDone(TOS_MsgPtr msg, result_t success)
	{
		//call ConsoleOut.print("Send done.\n");
		call RadioControl.adjustPAOutput(paValue);
		if (paValue == 0) paValue = 17;
		paValue--;
		bufLen++;
		if (bufLen > 29) bufLen = 0;
		packet.length = bufLen;
		call Timer.start(TIMER_ONE_SHOT, 300);
		return SUCCESS;
	}

	event TOS_MsgPtr Receive.receive(TOS_MsgPtr rcvPacket)
	{
		//call Leds.redToggle();
/*		if (rcvPacket->crc) {
			call ConsoleOut.print("Received packet: ");
			//call ConsoleOut.printStr(rcvPacket->data, rcvPacket->length);
			call ConsoleOut.print("\nStrength: ");
			call ConsoleOut.printHex(rcvPacket->strength);
			call ConsoleOut.print("\n");
			call Leds.blueToggle();
		} else {
			call ConsoleOut.print("Bad packet received.\n");
		}*/
		return rcvPacket;
	}

	task void edTask()
	{
		//call Leds.greenToggle();
		call ConsoleOut.print("Doing CCA.\n");
		call RadioCCA.clearChannelAssessment(0x80);
		call ConsoleOut.print("Returned from CCA\n");
		//call Timer.start(TIMER_ONE_SHOT, 3000);
	}
	
	task void dozeTask()
	{
		if (!dozing) {
			call Leds.greenToggle();
			call RadioPowerMng.doze(0, FALSE);
			dozing = TRUE;
		} else {
			call Leds.yellowToggle();
			call RadioPowerMng.wake();
			dozing = FALSE;
		}
		call Timer.start(TIMER_ONE_SHOT, 3000);
	}
	
	task void hibernateTask()
	{
		if (!dozing) {
			//call Leds.greenToggle();
			call RadioPowerMng.hibernate();
			dozing = TRUE;
		} else {
			//call Leds.yellowToggle();
			call RadioPowerMng.wake();
			dozing = FALSE;
		}
		call Timer.start(TIMER_ONE_SHOT, 15000);			
	}

	event void RadioPowerMng.dozeDone()
	{
		call ConsoleOut.print("Done dozing.. Still a little tired, though!\n");
	}
	
	event void RadioPowerMng.wakeDone()
	{
		call ConsoleOut.print("I was awaken.. Still a little tired, though!\n");	
	}
	
	async event void RadioCCA.energyDetectDone(uint8_t power)
	{
		call ConsoleOut.print("Energy detection done: ");
		call ConsoleOut.printHex(power);
		call ConsoleOut.print("\n");
		post edTask();
	}
	
	async event void RadioCCA.clearChannelAssessmentDone(bool isClear)
	{
		if(isClear) {
			call ConsoleOut.print("Channel clear!\n");
		} else {
			call ConsoleOut.print("Channel busy!\n");
		}
	}
	
	event result_t RadioControl.resetIndication()
	{
		call ConsoleOut.print("I was reset..\n");
		return SUCCESS;
	}

	/* We transmit a packet each time the timer fires */
	event result_t Timer.fired()
	{
		//call Leds.yellowToggle();
		return transmitPacket();
		//return post dozeTask();
		//return post hibernateTask();
		//return post edTask();
		// return SUCCESS;
	}
}
