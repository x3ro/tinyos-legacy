
module TestMacFrameMacroM
{
	provides {
		interface StdControl;
	}
	uses {
		interface Leds;
		interface Timer;
		interface ConsoleOutput as ConsoleOut;
		interface mc13192Receive as Receive;
		interface mc13192Send as Send;
		interface mc13192Control as RadioControl;
	}
}
implementation
{	
	// Testing frame macros.
	uint8_t tstPacket[11] = {0x03, 0x08, 0x4E, 0xFF, 0xFF, 0xFF, 0xFF, 0x07};
	uint8_t associateRequest[19] = {0x23, 0xC8, 0x7D, 0xEF, 0xBE, 0x00, 0x01, 0xFF, 0xFF, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01, 0x80};
 	uint8_t buf[7][125];
	uint8_t processMHR(uint8_t *packet);
	void processBeacon(uint8_t *packet);
	void processCommandFrame(uint8_t *packet);
	//task void enableRadioTask();
 
	/* **********************************************************************
	 * Setup/Init code
	 * *********************************************************************/

	/* Init */
	command result_t StdControl.init()
	{
		return SUCCESS;
	}

	/* start */
	command result_t StdControl.start()
	{
		//processMHR(tstPacket);
		call RadioControl.setChannel(0);
		call Receive.initRxQueue(buf[0]);
		call Receive.initRxQueue(buf[1]);
		call Receive.initRxQueue(buf[2]);
		call Receive.initRxQueue(buf[3]);
		call Receive.initRxQueue(buf[4]);
		call Receive.initRxQueue(buf[5]);
		call Receive.initRxQueue(buf[6]);
		call Timer.start(TIMER_ONE_SHOT, 3000);
		//call Receive.enableReceiver(0);
		return SUCCESS;
	}

	/* stop - never called */
	command result_t StdControl.stop()
	{
		return SUCCESS;
	}

	/* **********************************************************************
	 * Timer/radio related code
	 * *********************************************************************/
	event void Send.sendDone(uint8_t *packet, result_t status)
	{
		call ConsoleOut.print("Got send done\n");
		call Receive.enableReceiver(0);
	}
	
	event uint8_t* Receive.dataReady(uint8_t *packet, uint8_t length, bool crc, uint8_t lqi)
	{
		uint8_t type;
		if (crc) {
			call ConsoleOut.print("Dumping raw packet:\n");
			call ConsoleOut.print("-------------------------------------------------\n\n0x");
			call ConsoleOut.dumpHex(packet, length, ", 0x");
			call ConsoleOut.print("\n\n---------------------------------------------\n\n");
			type = processMHR(packet);
			if (type == 0) {
				//Beacon frame.
				processBeacon(packet);
			} else if (type == 3) {
				processCommandFrame(packet);
			}
		}
		//post enableRadioTask();
		return packet;
	}
	
/*	task void enableRadioTask()
	{
		call Receive.enableReceiver(buf, 128, 0x01, 0);
	}*/
	
	uint8_t processMHR(uint8_t *packet)
	{
		uint8_t frameType = mhrFrameType(packet);
		uint8_t secEnabled = mhrSecurityEnabled(packet);
		uint8_t framePend = mhrFramePending(packet);
		uint8_t ackRequest = mhrAckRequest(packet);
		//uint8_t intraPan = mhrIntraPan(packet);
		uint8_t seqNum = mhrSeqNumber(packet);
		uint8_t dstAddrLen = mhrDestAddrLength(packet);
		uint8_t srcAddrLen = mhrSrcAddrLength(packet);
		
		// Print sequence number.
		call ConsoleOut.print("Frame sequence number is: 0x");
		call ConsoleOut.printHex(seqNum);
		call ConsoleOut.print("\n");
		
		// Resolve frame type.
		call ConsoleOut.print("Frame type is: ");
		if (frameType == 0x0) {
			call ConsoleOut.print("Beacon frame");
		} else if (frameType == 0x1) {
			call ConsoleOut.print("Data frame");
		} else if (frameType == 0x2) {
			call ConsoleOut.print("Acknowledgement frame");
		} else if (frameType == 0x3) {
			call ConsoleOut.print("MAC command frame");
		} else {
			call ConsoleOut.print("Unknown frame type");
		}
		call ConsoleOut.print("\n");
	
		// Security
		if (secEnabled) {
			call ConsoleOut.print("Security is enabled\n");
		}
		
		// Pending frame
		if (framePend) {
			call ConsoleOut.print("Frame is pending\n");
		}
		
		// Ack requested?
		if (ackRequest) {
			call ConsoleOut.print("Acknowledgement was requested\n");
		}
	
		// Resolve addressing.
		if (mhrDestPANIdLength(packet)) {
			call ConsoleOut.print("Destination PAN Id is: 0x");
			call ConsoleOut.dumpHex(mhrDestPANId(packet), 2, "");
			call ConsoleOut.print("\n");
		}
		if (dstAddrLen) {
			call ConsoleOut.print("Destination address is: 0x");
			call ConsoleOut.dumpHex(mhrDestAddr(packet), dstAddrLen, "");
			call ConsoleOut.print("\n");
		}
		if (mhrSrcPANIdLength(packet)) {
			call ConsoleOut.print("Source PAN Id is: 0x");
			call ConsoleOut.dumpHex(mhrSrcPANId(packet), 2, "");
			call ConsoleOut.print("\n");
		}
		if (srcAddrLen) {
			call ConsoleOut.print("Source address is: 0x");
			call ConsoleOut.dumpHex(mhrSrcAddr(packet), srcAddrLen, "");
			call ConsoleOut.print("\n");
		}
		
		return frameType;
	}

	void processBeacon(uint8_t *packet)
	{
		uint8_t beaconOrder = msduBeaconOrder(packet);
		uint8_t superframeOrder = msduSuperframeOrder(packet);
		uint8_t finalCAPSlot = msduFinalCAPSlot(packet);
		uint8_t batteryLifeExt = msduBatteryLifeExtension(packet);
		uint8_t panCoordinator = msduPANCoordinator(packet);
		uint8_t assocPermit = msduAssociationPermit(packet);
		
		uint8_t gtsCount = msduGTSDescriptorCount(packet);
		
		// Print beacon order.
		call ConsoleOut.print("Beacon order is: 0x");
		call ConsoleOut.printHex(beaconOrder);
		call ConsoleOut.print("\n");

		// Print superframe order.
		call ConsoleOut.print("Superframe order is: 0x");
		call ConsoleOut.printHex(superframeOrder);
		call ConsoleOut.print("\n");
		
		// Print final cap slot.
		call ConsoleOut.print("Final CAP slot is: 0x");
		call ConsoleOut.printHex(finalCAPSlot);
		call ConsoleOut.print("\n");
		
		// battery ext
		if (batteryLifeExt) {
			call ConsoleOut.print("Battery life extension is set.\n");
		}
		
		// pan coordinator
		if (panCoordinator) {
			call ConsoleOut.print("Beacon originates from PAN coordinator.\n");
		}
		
		// association permit
		if (assocPermit) {
			call ConsoleOut.print("Association is permitted.\n");
		}
		
		if (msduGTSPermit(packet)) {
			call ConsoleOut.print("The coordinator accepts GTS requests\n");
		}
		
		// Process GTS info.
		if (gtsCount) {
			uint8_t i;
			uint8_t GTSListdirs = msduGTSDirectionMask(packet);
			msduGTSList_t *list = msduGTSList(packet);
			call ConsoleOut.print("We have GTS descriptors:\n");
			for (i=0;i<gtsCount;i++) {
				call ConsoleOut.print("\nGTS descriptor ");
				call ConsoleOut.printHex(i);
				call ConsoleOut.print("\n");
				call ConsoleOut.print("-------------------\n");
				call ConsoleOut.print("Device address = 0x");
				call ConsoleOut.printHexword(list[i].DeviceShortAddress);
				call ConsoleOut.print("\n");
				call ConsoleOut.print("GTS starting slot = 0x");
				call ConsoleOut.printHex(list[i].GTSStartingSlot);
				call ConsoleOut.print("\n");
				call ConsoleOut.print("GTS length = 0x");
				call ConsoleOut.printHex(list[i].GTSLength);
				call ConsoleOut.print("\n");
				if (GTSListdirs & (1<<i)) {
					call ConsoleOut.print("GTS slot is receive only!\n");
				} else {
					call ConsoleOut.print("GTS slot is transmit only!\n");
				}
			}
		}
		
	}

	void processCommandFrame(uint8_t *packet)
	{
		uint8_t ident = msduCommandFrameIdent(packet);

		// Print command identifier.
		if (ident == 0x01) {
			call ConsoleOut.print("Association request!\n");
			if (msduAltPANCoordinator(packet)) {
				call ConsoleOut.print("Device is capable of becoming a PAN coordinator\n");
			}
			if (msduDeviceType(packet)) {
				call ConsoleOut.print("Device is an FFD\n");
			} else {
				call ConsoleOut.print("Device is an RFD\n");
			}
			if (msduPowerSource(packet)) {
				call ConsoleOut.print("Device is externally powered\n");
			}
			if (msduRecvOnWhenIdle(packet)) {
				call ConsoleOut.print("Device keeps receiver on when idle\n");
			}
			if (msduSecurityCapability(packet)) {
				call ConsoleOut.print("Device is able to process secured frames\n");
			}
			if (msduAllocateAddress(packet)) {
				call ConsoleOut.print("The coordinator should allocate a short address for the device\n");
			}
		} else if (ident == 0x02) {
			uint8_t status = msduAssocResponseStatus(packet);
			call ConsoleOut.print("Association response!\n");
			if (status == 0x00) {
				call ConsoleOut.print("Association was successful\n");
				call ConsoleOut.print("Got short address: 0x");
				call ConsoleOut.dumpHex(msduAssocResponseShortAddr(packet), 2, "");
				call ConsoleOut.print("\n");
			} else if (status == 0x01) {
				call ConsoleOut.print("PAN at capacity!\n");
			} else if (status == 0x02) {
				call ConsoleOut.print("PAN access denied!\n");
			} else {
				call ConsoleOut.print("Unknown status!\n");
			}
		} else if (ident == 0x03) {
			uint8_t reason = msduDisassocReason(packet);
			call ConsoleOut.print("Disassociation notification!\n");
			if (reason == 0x01) {
				call ConsoleOut.print("Coordinator wishes the device to leave the PAN\n");
			} else if (reason == 0x02) {
				call ConsoleOut.print("Device wishes to leave the PAN\n");
			} else {
				call ConsoleOut.print("Unknown reason!\n");
			}
		} else if (ident == 0x04) {
			call ConsoleOut.print("Data request!\n");
		} else if (ident == 0x05) {
			call ConsoleOut.print("PAN ID conflict notification!\n");
		} else if (ident == 0x06) {
			call ConsoleOut.print("Orphan notification!\n");
		} else if (ident == 0x07) {
			call ConsoleOut.print("Beacon request!\n");
		} else if (ident == 0x08) {
			call ConsoleOut.print("Coordinator realignment!\n");
		} else if (ident == 0x09) {
			call ConsoleOut.print("GTS request!\n");
		} else {
			call ConsoleOut.print("Unknown command!\n");
		}
	}

	event void Receive.timeout(uint8_t *packet) {}
	async event void Receive.wordReady(uint16_t data) {}
	event result_t RadioControl.resetIndication() {return SUCCESS;}
	
	event result_t Timer.fired()
	{
		result_t res;
		res = call Send.send(associateRequest, 19, 0, TRUE);
		if (res) {
			call ConsoleOut.print("Receiver enabled");
		}
		return SUCCESS;
	}
}
