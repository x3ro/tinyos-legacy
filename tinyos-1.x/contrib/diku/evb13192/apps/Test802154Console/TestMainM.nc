/* $Id: TestMainM.nc,v 1.3 2005/04/14 13:16:50 janflora Exp $ */
/** Test application for SimpleMac

  Copyright (C) 2004 Mads Bondo Dydensborg, <madsdyd@diku.dk>

  This program is free software; you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation; either version 2 of the License, or
  (at your option) any later version.

  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with this program; if not, write to the Free Software
  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

*/

/** Test application for 802.15.4.
 *
 * <p>The purpose of this application is to test and demonstrate the
 * support for the Freescale 802.15.4 stack, using a slightly modified
 * version of the TinyOS 802.15.4 interface (which resides in
 * beta/lib/ in TinyOS 1.x, and may change for TinyOS 2.0). The
 * program is written with clarity in focus, not effeciency.</p>
 *
 * <p>The basic idea is to provide an interactive console
 * interface. Using this interface, various commands can be initiated,
 * and the results inspected.</p>
 *
 * <p>The interface used are a "control" interface, which models the
 * ASP interface in the Freescale libraries. Use this to initialize
 * the interface, and call the methods that are available through the
 * ASP interface, such as Doze and others.</p>
 *
 * <p>The TinyOS interface used have been modified to return an error
 * code, if the various commands does not succeed.</p>
 *
 * <p>Note, not all commands are supported by the TinyOS stack, nor
 * tested by this program, but it is easy to write any missing
 * functionality.</p>
 *
 * <p>Note, that you should check the documentation for the
 * Freescale802154Control interface for more information about
 * properly initializing the stack, setting up clocks, etc. This is
 * quite an tricky process...</p>
 *
 * @author Mads Bondo Dydensborg, <madsdyd@diku.dk>, Jan. 2005.
 *
 * Note: This is a work in progress.
 */
// includes hcs08hardware;
// includes IEEE802154;
module TestMainM
{
	provides
	{
		interface StdControl;
	}
	uses
	{
		interface Freescale802154Control as Control;
		interface MLME_GET;
		interface MLME_SCAN;
		interface MLME_SET;
		interface MLME_START;
		interface MLME_ASSOCIATE;
		interface MLME_DISASSOCIATE;
		interface MCPS_DATA;
		interface Timer;
		interface Leds;
		interface Console;
	}
}
implementation
{
	// Message for passing to the asp layer, allocated here, to not break the stack.
	aspMsg_t msg;
	
	// The selected logical channel is store in here, initialized to 11
	uint8_t logicalChannel = 11;
	uint8_t *EDList;

	// Global variable used for activty -> association (Yes, ugly, fix it :-)
	panDescriptor_t panInfo;
	uint8_t ResListSize;
	PANDescriptor_t *PDList;

	bool AssocFlag = TRUE;

	/* Testing doze */
	bool_t weAreDozing = FALSE;

	/** Short address we got */
	uint16_t panClientShort;

	char * sendbuffer = "Hello World!";

	/** Used to keep the commands the user type in */
	char cmd_input[200];
	char * bufpoint;

	/** Store data from the Console.get event here. */
	char console_data;

	/* Print a prompt - definition follows below */
	void prompt();

	/* **********************************************************************
	 * Setup/Init code
	 * *********************************************************************/

	/* *************************************************************************/
	/**
	 * Init.
	 *
	 * <p>Sets up our send buffer, inits hardware.</p>
	 *
	 * @return SUCCESS always.
	 */
	/* *************************************************************************/
	command result_t StdControl.init()
	{
		/* Just make sure that something happens. */
		call Leds.init();
		call Leds.redOn();

		/* Set up our command buffer */
		bufpoint = cmd_input;
		*bufpoint = 0;

		/* Other init */
		call Console.init();
		if (!call Control.init()) {
			// call Console.print("\nError initalizing Freescale Mac Layer!\n");
			call Leds.yellowOn();
		} else {
			// call Console.print("\n\rTestMainM.nc (802.15.4) booted\n\r");
			call Leds.greenOn();
		}
		// TODO: Reinitialize timers after Control have been initialized?
		return SUCCESS;
	}

	/* *************************************************************************/
	/**
	 * Start
	 *
	 * <p>Get the timer going.</p>
	 *
	 * @return SUCCESS if the timer was started, FAIL otherwise.
	 */
	/* *************************************************************************/
	command result_t StdControl.start()
	{
		prompt();
		return call Timer.start(TIMER_REPEAT, 1000);
	}

	/* *************************************************************************/
	/**
	 * Stop.
	 *
	 * <p>Never really called, but we kill the timer.</p>
	 *
	 * @return SUCCESS if the timer was stopped, FAIL otherwise.
	 */
	/* *************************************************************************/
	command result_t StdControl.stop()
	{
		return call Timer.stop(); 
	}

 
	/* *************************************************************************/
	/**
	 * Timer fired handler.
	 *
	 * <p>For now, just toggle a led.</p>
	 *
	 * @return SUCCESS always.
	 */
	/**************************************************************************/
	event result_t Timer.fired()
	{
		call Leds.yellowToggle();
		return SUCCESS;
	}


	/* **********************************************************************
	 * 802.15.4 stuff.
	 * Note, the 802.15.4 interface that TinyOS defines, is spread over 
	 * a lot of interface files.
	 * *********************************************************************/
  
	/* ********************************************************************** */
	/**
	 * Task that retrieves the current time from the ASP layer.
	 */
	/* ********************************************************************** */
	task void getTime()
	{
		msg.msgType = gAppAspGetTimeReq_c;
		if (gSuccess_c != MSG_Send(APP_ASP, &msg)) {
			call Console.print("Error calling MSG_Send\n");
		} else {
			call Console.print("0x");
			call Console.printHex(msg.aspToAppMsg.msgData.appGetTimeCfm.time[2]);
			call Console.printHex(msg.aspToAppMsg.msgData.appGetTimeCfm.time[1]);
			call Console.printHex(msg.aspToAppMsg.msgData.appGetTimeCfm.time[0]);
			call Console.print("\n");
		}
		prompt();
	}

	/* ********************************************************************** */
	/**
	 * Task that request a wake.
	 *
	 * <p>Broken, I think.</p>
	 */
	/* ********************************************************************** */
	task void getWake()
	{
		msg.msgType = gAppAspWakeReq_c;
		if (gSuccess_c == MSG_Send(APP_ASP, &msg)) {
			call Console.print("Wake requested\n");
		} else {
			call Console.print("Error calling MSG_Send\n");
		}
		prompt();
	}

	/////
	// Functions testing MLME_SCAN Interface.
	////////
	
	/* ********************************************************************** */
	/** Post an activity scan, that is, talk to the MLME layer.
	 *
	 * <p>Scans all channels, as indicated by the 0x07FFFF800 bit mask,
	 * each channel is scanned for approximately 0.5 seconds (indicated
	 * by the 5, note, there is a non linear relation between 0.5 secs
	 * and 5).</p> 
	 */
	/* ********************************************************************** */
	task void ascan() {
		/* Activity scan, all channels, approximately 0.5 sec on each */
		call Console.print("Starting active scan ... ");
		call MLME_SCAN.request(gScanModeActive_c, 0x07FFF800, 5);
	}

	/* ********************************************************************** */
	/** Post an energy detection scan, that is, talk to the MLME layer.
	 *
	 * <p>Scans all channels, as indicated by the 0x07FFFF800 bit mask,
	 * each channel is scanned for approximately 0.5 seconds (indicated
	 * by the 5, note, there is a non linear relation between 0.5 secs
	 * and 5).</p> 
	 */
	/* ********************************************************************** */
	task void edscan()
	{
		/* Energy scan, all channels, approximately 0.5 sec on each */
		call Console.print("Starting energy detection scan ...");
		call MLME_SCAN.request(gScanModeED_c, 0x07FFF800, 5);
	}

	/* ********************************************************************** */
	/** 
	 * Handle the result of the energy detection scan.
	 *
	 * <p>This task does printing outside interrupt context. We should
	 * really store the msg, then examine it here, instead of the
	 * interrupt context. Must think about the memory management of the
	 * interface/802.15.4 layer. </p>
	 */
	/* ********************************************************************** */
	task void edscanTask()
	{
		uint8_t n,minEnergy;
		/* Set the minimum energy to a large value */
		minEnergy = 0xFF;
		/* Select default channel */
		logicalChannel = 0;
      
		/* Search for the channel with least energy */
		for(n=0; n<16; n++) {
			if(EDList[n] < minEnergy) {
				minEnergy = EDList[n];
				logicalChannel = n;
			}
		}
      
		/* Channel numbering is 11 to 26 both inclusive */
		logicalChannel += 11;
		
		call Console.print("Selected channel ");
		call Console.printHex(logicalChannel);
		call Console.print("\n"); 
		prompt();
	}

	/* ********************************************************************** */
	/** 
	 * Handle the result of the activity scan.
	 *
	 * <p>This task does printing outside interrupt context. We should
	 * really store the msg, then examine it here, instead of the
	 * interrupt context. Must think about the memory management of the
	 * interface/802.15.4 layer. </p>
 	*/
	/* ********************************************************************** */
	task void acscanTask()
	{
		uint8_t bestLinkQuality = 0;
		uint8_t i;
		panDescriptor_t *bestLinkInfo = NULL;
		panDescriptor_t *panDesc = ((panDescriptor_t *) PDList);
		//asm("bgnd");	
		for (i = 0; i < ResListSize; i++) {
			// NOTE: Due to differences between the Freescale pan descriptor
			// and the TinyOS interface one, we must typecast here...
			// Only associate if ok, and non beacon.
			if ( (panDesc->superFrameSpec[1] & gSuperFrameSpecMsbAssocPermit_c) &&
			     (panDesc->superFrameSpec[0] & gSuperFrameSpecLsbBO_c) == 0xF ) {
				// Get the best
				if (panDesc->linkQuality > bestLinkQuality) {
					bestLinkQuality = panDesc->linkQuality;
					bestLinkInfo = panDesc;
				}
			}
			panDesc++;
		}

		if (bestLinkInfo) {
			memcpy(&panInfo, bestLinkInfo, sizeof(panDescriptor_t));
			//panInfo = *bestLinkInfo;
			//This is where everything is A-OK.
		} else {
			call Console.print("No best link?\n");
			return;
		}
		call Console.print("acscan found coordinator (note, byte order broken):\n");
		call Console.print("Address 0x"); 
		if (panInfo.coordAddrMode == gAddrModeShort_c) {
			call Console.printHexword(*((uint16_t *)panInfo.coordAddress));
		} else {
			call Console.dumpHex(panInfo.coordAddress, 8, "");
		}
		call Console.print("\nPAN ID 0x");
		call Console.printHexword(*((uint16_t *)panInfo.coordPanId));
    
		call Console.print("\nLogical Channel 0x"); 
		call Console.printHex(panInfo.logicalChannel);
    
		call Console.print("\nBeacon Spec 0x"); 
		call Console.printHexword(*((uint16_t *)(panInfo.superFrameSpec)));
    
		call Console.print("\nLink Quality 0x"); 
		call Console.printHex(panInfo.linkQuality);
		call Console.print("\n");
		prompt();
	}

	/* ********************************************************************** */
	/** 
	 * Handle the result of the scan (event).
	 *
	 * <p>Traverse all channels, select the one with the least energy on
	 * (cleanest), and store it in the global variable logicalChannel,
	 * then post a task to print the result.</p>
	 *
	 * <p>Based on code from the Wireless App Demo.</p> 
	 */
	/* ********************************************************************** */
	event void MLME_SCAN.confirm(IEEE_status status,
	                             uint8_t ScanType,
	                             uint32_t UnscannedChannels,
	                             uint8_t ResultListSize,
	                             uint8_t* EnergyDetectList,
	                             PANDescriptor_t* PANDescriptorList)
	{
		switch(ScanType) {
		
			// Energy Detection Scan
 			case gScanModeED_c: {
				
 				if (status != gSuccess_c) {
 					break;
 				}
 				EDList = EnergyDetectList;
				post edscanTask();
				break;
			}
			// Active Scan
			case gScanModeActive_c: {
				
				/* Check status */
				if (status == ASUCCESS) {
					call Console.print("Active scan successful\n");
					if (ResultListSize == 0) {
						call Console.print("No results!\n");
						break;
					}
					PDList = PANDescriptorList;
					ResListSize = ResultListSize;
					post acscanTask();

				} else if (status == NO_BEACON) {
					//asm("bgnd");
					call Console.print("No beacon in ac scan :-(\n");
					//asm("bgnd");
				} else {
					call Console.print("Unknown status: 0x");
					call Console.printHex(status);
					call Console.print("\n");
				}
				break;
			}
			// Passive scan mode
			case gScanModePassive_c:
				if (status == gSuccess_c) {
				} else if (status == gNoBeacon_c) {
				} else {
					call Console.print("Unknown status: 0x");
					call Console.printHex(status);
					call Console.print("\n");
				}
				call Console.print("Passive scan not implemented yet!");
				break;

			// Orphan scan mode
			case gScanModeOrphan_c:
				if (status == gSuccess_c) {
				} else if (status == gNoBeacon_c) {
				} else {
					call Console.print("Unknown status: 0x");
					call Console.printHex(status);
					call Console.print("\n");
				}
				call Console.print("Orphan scan not implemented yet!");
				break;
    				
    			default:
				call Console.print("MLME_SCAN.confirm on unknown event!\n");
      	}
	}


	// Functions used to start a PAN coordinator.

	/* ********************************************************************** */
	/**
	 * Setting the short addres.
	 *
	 * <p>Sets the short address to TOS_LOCAL_ADDRESS, by calling </p>
	 */
	/* ********************************************************************** */
	task void setshort() {
		call Console.print("Setting short address\n");
		// NOTE: The use of & in TOS_LOCAL_ADDRESS - need global address
		// Or, maybe perhaps not, the SET request is synchrounous, I think.
		// See the user guide.
		call MLME_SET.request(IEEE802154_macShortAddress, &TOS_LOCAL_ADDRESS);
 		prompt();
	}

	event void MLME_SET.confirm(IEEE_status status, uint8_t PIBAttribute) {
		switch(PIBAttribute) {
			case IEEE802154_macShortAddress:
				call Console.print("MLME_SET.confirm for macShortAddress\n");
				break;
      
			case IEEE802154_macAssociationPermit:
				call Console.print("MLME_SET.confirm for macAssociationPermit\n");
				break;

			default:
				call Console.print("Unknown PIB set");
		}
	}

	/* ********************************************************************** */
	/**
	 * Starting a PAN
	 *
	 * <p>Starts a PAN - assumes that we have set things like
	 * logicalChannel, etc.</p>
	 *
	 * <p>Note, that the Freescale hardware leaves RX on after a PAN
	 * start. This is not standard behaviour, as far as I know.</p>
	 */
	/* ********************************************************************** */
	task void startpan() {
		call Console.print("Starting PAN\n");
		// Note, that the panid should not be hardcoded... :-)
		call MLME_START.request(0xBEEF,  // panid 
		                        11, // logicalChannel. 11 is first 2.4GHz channel. 
		                        0x0F, // turn off beacons
		                        0x0F, // turn off superframes
		                        TRUE, // Be a PAN Coordinator
		                        FALSE, // No bat life ext.
		                        FALSE, // Not a realignment
		                        FALSE);  // No security
		prompt();
	}

	/* The event handler, no clue what the status is, should probably
	   check the 802.15.4 stanard for that */
	event void MLME_START.confirm(IEEE_status status) {
		call Console.print("MLME_START.confirm, status: 0x");
		call Console.printHex(status);
		call Console.print("\n");
	}

	/* ********************************************************************** */
	/**
	 * Set the association status
	 *
	 * <p>This PIB setting must be set after starting the PAN.</p>
	 */
	/* ********************************************************************** */
 
	task void setassoc() {
		call Console.print("Setting association bit\n");
		// NOTE: The use of & in AssocFlag - need global address Or, maybe
		// perhaps not, the SET request is synchrounous, I think.  See the
		// user guide.The callback is handled above.
		call MLME_SET.request(IEEE802154_macAssociationPermit, &AssocFlag);
		prompt();
	}


	// Functions for testing association and disassociation.

	task void disassoc()
	{
		call Console.print("Disassociating from PAN ... ");
		call MLME_DISASSOCIATE.request(*((uint64_t*)panInfo.coordAddress),2,FALSE);
	}

	/* ********************************************************************** */
	/**
	 * Respond to an association request.
	 *
	 * <p>For now, just print a message.</p>
	 */
	/* ********************************************************************** */
	event void MLME_DISASSOCIATE.indication(uint64_t DeviceAddress,
	                                        IEEE_status DisassociateReason,
	                                        bool SecurityUse,
	                                        uint8_t ACLEntry)
	{
		call Console.print("MLME_DISASSOCIATE.indication\n");
		call Console.print("Device is at ");
		call Console.dumpHex((uint8_t *)&DeviceAddress, 8, "");
		call Console.print("\n");
	}
  
	/* ********************************************************************** */
	/**
	 * We got associated.
	 *
	 * <p>For now, just print a message.</p>
	 */
	/* ********************************************************************** */
	event void MLME_DISASSOCIATE.confirm(IEEE_status status)
	{
		call Console.print("MLME_DISASSOCIATE.confirm, check status\n");
		call Console.print("status: 0x");
		call Console.printHex(status);
		call Console.print("\n");
	}

	/* ********************************************************************** */
	/**
	 * Associate to a pan.
	 *
	 * <p>Use the value found in ascan to associate to a PAN</p>
	 */
	/* ********************************************************************** */
	task void associate() {
		call Console.print("Associating to PAN ... ");
		call MLME_ASSOCIATE.request(panInfo.logicalChannel,
		                            panInfo.coordAddrMode,
		                            *((uint16_t *) panInfo.coordPanId),
		                            panInfo.coordAddress,
		                            gCapInfoAllocAddr_c, // ask coordinator to allocate short addr.
		                            FALSE);
	}
  
	/* ********************************************************************** */
	/**
	 * Respond to an association request.
	 *
	 * <p>For now, just print a message.</p>
	 */
	/* ********************************************************************** */
	event void MLME_ASSOCIATE.indication(uint64_t DeviceAddress,
	                                     uint8_t CapabilityInformation,
	                                     bool SecurityUse,
	                                     uint8_t ACLEntry)
	{
		call Console.print("Device is at ");
		call Console.dumpHex((uint8_t *)&DeviceAddress, 8, "");
		call Console.print("\n");

		// !!! JMS: Fixed address, not sure about the values, look at!
		call MLME_ASSOCIATE.response(DeviceAddress, 0xDEAD, 0, FALSE);
		prompt();
	}
  
	/* ********************************************************************** */
	/**
	 * We got associated.
	 *
	 * <p>For now, just print a message.</p>
	 */
	/* ********************************************************************** */
	event void MLME_ASSOCIATE.confirm(uint16_t AssocShortAddress,
	                                  IEEE_status status)
	{
		call Console.print("MLME_ASSOCIATE.confirm, check status and address\n");
		call Console.print("Short address: 0x");
		call Console.printHexword(AssocShortAddress);
		call Console.print(", status: 0x");
		call Console.printHex(status);
		call Console.print("\n");
		panClientShort = AssocShortAddress;
	}

	event void MLME_GET.confirm(IEEE_status status, uint8_t pibAttribute, void *pibAttributeValue)
	{
		call Console.print("MLME_GET.confirm:\n");
		call Console.print("Result was: 0x");
		call Console.printHex(*(uint8_t*)pibAttributeValue);
		call Console.print("\n");
	}

	/* ********************************************************************** */
	/**
	 * We got a communication status.
	 *
	 * <p>Implement!.</p>
	 */
	/* ********************************************************************** */
	//event void MLME-COMM-STATUS.indication(uint16_t PANId, SrcAddrMode, SrcAddr, DstAddrMode, DstAddr, status

	/* ********************************************************************** */
	/**
	 * test the get functionality
	 *
	 * @param
	 * @return
	 */
	/* ********************************************************************** */
  
	task void testGet()
	{
		call MLME_GET.request(gMacRole_c);  
	} 

	// Functions used to test sending data over the radio.

	/* ********************************************************************** */
	/**
	 * Testing send.
	 *
	 * !!! JMS: fix msduHandle, msduLength not sizeof(sendbuffer) but something else than 12...
 	 * @param
 	 * @return
	 */
	/* ********************************************************************** */
	task void send() {
		uint8_t SrcAddrMode;
		uint8_t SrcAddr[8];
		uint16_t coPanId;

		if (panClientShort == 0xFFEE) {
			call Console.print("Sending using extended address\n");
			SrcAddrMode = 3;
			memcpy((void *) SrcAddr, (void *) aExtendedAddress, 8);
		} else {
			call Console.print("Sending using short address\n");
			SrcAddrMode = 2;
			memcpy((void *) SrcAddr, (void *) &panClientShort, 2);
		}
		memcpy(&coPanId, panInfo.coordPanId, 2);
    
		call MCPS_DATA.request(SrcAddrMode, coPanId, SrcAddr,
		                       panInfo.coordAddrMode, coPanId, panInfo.coordAddress,
		                       12, (uint8_t *)sendbuffer, 0x42, gTxOptsAck_c);
	}
	
	/* **********************************************************************
	 * Broken handlers
	 * *********************************************************************/
	event void MCPS_DATA.confirm(uint8_t msduHandle,
	                             IEEE_status status)
	{
		call Console.print("In MCPS_DATA.confirm\n");
	}

	event void MCPS_DATA.indication (uint8_t SrcAddrMode,
	                                 uint16_t SrcPANId,
	                                 uint8_t* SrcAddr,
	                                 uint8_t DstAddrMode,
	                                 uint16_t DstPANId,
	                                 uint8_t* DstAddr,
	                                 uint8_t msduLength,
	                                 uint8_t* msdu,
	                                 uint8_t mpduLinkQuality,
	                                 bool SecurityUse,
	                                 uint8_t ACLEntry)
	{
		call Console.print("In MCPS_DATA.indication\n");
	}

	/* ********************************************************************** */
	/** Testing doze mode. Now, this is tricky, keep tounge in cheek

	    One would probably want to move this (and other calls to the ASP
	    interface) into the control interface. 

	    What to do about the needed stop code (if we want to powersave?
	    Does TinyOS have a power management API we should support, or is
	    it only AMStandard that have that?
	*/
  
	task void doze()
	{
		aspDozeReq_t * pDozeReq;
    
		// Normally we would check for data before going into doze, see PTC demo.
		// Set the type
		msg.msgType = gAppAspDozeReq_c;
    
		// Convenient pointer...
		pDozeReq = &msg.appToAspMsg.msgData.aspDozeReq;

		/* This duration is about 5 seconds. */
		pDozeReq->dozeDuration[0] = 0xB4;
		pDozeReq->dozeDuration[1] = 0xC4;
		pDozeReq->dozeDuration[2] = 0x04;
    
		if (gSuccess_c != MSG_Send(APP_ASP, &msg)) {
			call Console.print("Error calling MSG_Send\n");
			prompt();
			return;
		}
		if (msg.aspToAppMsg.msgData.appDozeCfm.status != gSuccess_c) {
			call Console.print("Error, no doze!\n");
		} else {
			/* At this point, when we send the message, we will lose the
			   clock from the radio. It will trigger an interrupt, which will
			   call the ICG_Setup function, which will go into selfclocked
			   mode. When we return here, we can go into stop, and will be
			   waked up by the radio later on: When the radio interrupts, the
			   interrupt handler in the PHY layer will call ICG_Setup, where
			   we can change to the radio clock again. Note, the call to ASP
			   will change the global variable gSeqPowerSaveMode */
			// SIMOPT = SOPT, PMCSC2 = SCPMSC2
			SOPT |= 0x20; SPMSC2 &= ~0x02; __asm("STOP");
		}
		// NOTE: We should check the return values/status call
		prompt();
	}

	/* ********************************************************************** */
	/**
	 * Print help task.
	 *
	 * <p>Prints help about how to set up as a pan coordinator or as a
	 * slave that joins a PAN</p>
	 */
	/* ********************************************************************** */
	task void help()
	{
		call Console.print("Try ls\n");
		call Console.print("To become PAN coordinator: setshort -> startpan -> setassoc\n");
		call Console.print("To join a PAN network: ascan -> associate -> send \n");
		prompt();
	}

	/* ********************************************************************** */
	/**
	 * Print info task.
	 *
	 * <p>Dumps our mac address and local TOS number </p>
	 */
	/* ********************************************************************** */
	task void info()
	{
		call Console.print("Everything after ascan is broken, I think, including a lot of byte ordering, memcpy/* operator stuff, and typecasting.\n");
		call Console.print("Node 0x");
		call Console.printHexword(TOS_LOCAL_ADDRESS);
		call Console.print(" has MAC extended address (broken, perhaps NV_RAM?)");
		call Console.dumpHex(aExtendedAddress, 8, "");
		call Console.print("\n");
		prompt();
	}

	/* **********************************************************************
	 * Handle stuff from the console
	 * *********************************************************************/
	 // Print a prompt.
	void prompt()
	{
		call Console.print("[root@evb13192-");
		call Console.printHexword(TOS_LOCAL_ADDRESS);
		call Console.print(" /]# ");
	}

	/** Help function, does string compare */
	int strcmp(const unsigned char * a, const unsigned char * b)
	{
		while (*a && *b && *a == *b) { ++a; ++b; };
		return *a - *b;
	}

	/**************************************************************************/
	/**
	 * Handle data from the console.
	 *
	 * <p>Simply dump the data, handle any commands by posting tasks.</p>
	 */
	/**************************************************************************/
	task void handleGet()
	{
		char console_transmit[2];
		atomic console_transmit[0] = console_data;
		console_transmit[1] = 0;
		call Leds.greenToggle();
		call Console.print(console_transmit); 

		/* Check if enter was pressed */
		if (console_transmit[0] == 10) {
			/* If enter was pressed, "handle" command */
			if (0 == strcmp("ls", cmd_input)) {
				call Console.print("ascan      doze    help  ls    setassoc  startpan  wake\n"
				                   "associate  edscan  info  send  setshort  time  disassoc\n");
			   prompt();
			} else if (0 == strcmp("", cmd_input)) {
				prompt();
			} else if (0 == strcmp("associate", cmd_input)) {
				post associate();
			} else if (0 == strcmp("ascan", cmd_input)) {
				post ascan();
			} else if (0 == strcmp("doze", cmd_input)) {
				post doze();
			} else if (0 == strcmp("edscan", cmd_input)) {
				post edscan();
			} else if (0 == strcmp("help", cmd_input)) {
				post help();
			} else if (0 == strcmp("info", cmd_input)) {
				post info();
			} else if (0 == strcmp("send", cmd_input)) {
				post send();
			} else if (0 == strcmp("setassoc", cmd_input)) {
				post setassoc();
			} else if (0 == strcmp("setshort", cmd_input)) {
				post setshort();
			} else if (0 == strcmp("disassoc", cmd_input)) {
				post disassoc();
			} else if (0 == strcmp("startpan", cmd_input)) {
				post startpan();
			} else if (0 == strcmp("time", cmd_input)) {
				post getTime();
			} else if (0 == strcmp("wake", cmd_input)) {
				post getWake();
			} else if (0 == strcmp("get", cmd_input)) {
				post testGet();		
			} else {
				call Console.print("tosh: ");
				call Console.print(cmd_input);
				call Console.print(": command not found\n");
				prompt();
			}
			/* Get ready for a new command */
			bufpoint = cmd_input;
			*bufpoint = 0;
		} else {
			/* Store character in buffer */
			if (bufpoint < (cmd_input + sizeof(cmd_input))) {
				*bufpoint = console_transmit[0];
				++bufpoint;
				*bufpoint = 0;
			}
		}
	}
  
	/**************************************************************************/
	/**
	 * Console data event.
	 *
	 * <p>We store the data, post a task.</p>
	 *
	 * @param data The data from the console.
	 * @return SUCCESS always.
	 */
	/**************************************************************************/
	async event result_t Console.get(uint8_t data) {
		atomic console_data = data;
		post handleGet();
		return SUCCESS;
	}

} /* End of compoment */
