#include <macTypes.h>
#include <Ieee802154Adts.h>
 // TODO: do not include this
#include <macConstants.h>
#include <phyTypes.h>
#include <MacPib.h>

module Test802154MacRadioOpLayerM
{
	provides
	{
		interface StdControl;
	}
	uses
	{
		interface IeeeRequestConfirm<Mlme_ScanRequestConfirm> as MlmeRequestConfirmScan;
		interface IeeeRequest<Mlme_SyncRequest> as MlmeRequestSync;
		interface IeeeIndication<Mlme_BeaconNotifyIndication> as MlmeIndicationBeaconNotify;
		
		interface MlmeBeaconNotifyIndication;
		interface MlmeScanRequestConfirm;
		interface MlmeSyncRequest;
		interface IeeePanDescriptor;
		interface IeeeAddress;
		
		interface RadioChannel;		
		interface FrameTx;
		interface RadioIdleControl;
		interface Debug;
		interface ConsoleInput as ConsoleIn;
		interface ConsoleOutput as ConsoleOut;
	}
}
implementation
{
	#define DBG_LEVEL 1
	#include "Debug.h"
	
	// The selected logical channel is store in here, initialized to 11
	uint8_t logicalChannel = 12;
	uint8_t *EDList;

	// Global variable used for activty -> association (Yes, ugly, fix it :-)
	Mlme_ScanRequestConfirm scanconfirm;
	panDescriptor_t tmpPan;
	Ieee_PanDescriptor panInfo = &tmpPan;
	
	txHeader_t testFrame;
	uint8_t myFrame[19] = {0x23, 0xC8, 0xFE, 0x00, 0x00, 0x00, 0x00, 0xFF, 0xFF, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01, 0x80};

	/** Used to keep the commands the user type in */
	char cmd_input[200];
	char * bufpoint;

	/** Store data from the Console.get event here. */
	char console_data;

	void recvOn(PhyStatus_t status);
	void txOn(PhyStatus_t status);
	void txDone();
	
	void prompt();
	task void ascan();
	task void pscan();
	task void edscan();
	task void sync();
	void scanTask();
	void edscanTask();
	
	int strcmp(const char * a, const char * b);
	task void handleGet();
	
	command result_t StdControl.init()
	{
		/* Set up our command buffer */
		bufpoint = cmd_input;
		*bufpoint = 0;
		return SUCCESS;
	}

	command result_t StdControl.start()
	{
		DBG_STR("Starting!",1);
		prompt();

		return SUCCESS;
	}

	command result_t StdControl.stop()
	{
		return FAIL;
	}
	
	task void rxOnTask()
	{
		if (call RadioChannel.setCurrentChannel(logicalChannel, recvOn) != SUCCESS) {
			DBG_STR("Could not set channel!",1);
		}
	}
	
	task void testTxTask()
	{
		if (call RadioChannel.setCurrentChannel(logicalChannel, txOn) != SUCCESS) {
			DBG_STR("Could not set channel!",1);
		}
	}
	
	void recvOn(PhyStatus_t status)
	{
		DBG_STR("Enabling receiver!",1);
		call RadioIdleControl.setRxOnWhenIdle();
	}
	
	void txOn(PhyStatus_t status)
	{
		DBG_STR("Testing transmission!",1);
		testFrame.frame = myFrame;
		testFrame.frameLength = 19;
		testFrame.txRetries = 3;
		testFrame.addDsn = TRUE;
		call FrameTx.tx(&testFrame, TRUE, txDone);
	}

	void txDone()
	{
		if (testFrame.status == TX_SUCCESS) {
			DBG_STR("Transmit was successful",1);
		} else if (testFrame.status == TX_NO_ACK) {
			DBG_STR("Frame transmitted but no ACK was received",1);
		} else if (testFrame.status == TX_CHANNEL_ACCESS_FAILURE) {
			DBG_STR("Couldn't access channel!",1);
		}
	}
	
	event void MlmeIndicationBeaconNotify.indication(Mlme_BeaconNotifyIndication indication)
	{
		DBG_STR("Got a beacon!",1);
		call MlmeBeaconNotifyIndication.destroy(indication);
	}
	
	event void MlmeRequestConfirmScan.confirm(Mlme_ScanRequestConfirm confirm)
	{
			uint8_t status,scanType,resultListSize;			
			status = call MlmeScanRequestConfirm.getStatus(confirm);
			call ConsoleOut.print("MlmeRequestConfirmScan.confirm, status ");
			call ConsoleOut.printHex(status);
			call ConsoleOut.print("\n");
			scanType = call MlmeScanRequestConfirm.getScanType(confirm);
			resultListSize = call MlmeScanRequestConfirm.getResultListSize(confirm);
			switch(scanType) {		
			// Energy Detection Scan
 			case IEEE802154_EDScan: {
				
 				if (status != IEEE802154_SUCCESS) {
 					break;
 				}
 				scanconfirm = confirm;
				edscanTask();
				break;
			}
			// Active Scan or passive scan
			case IEEE802154_PassiveScan:
			case IEEE802154_ActiveScan: {
				
				/* Check status */
				if (status == IEEE802154_SUCCESS) {
//					call ConsoleOut.print("Active scan successful\n");
					scanconfirm = confirm;
					scanTask();

				} else if (status == IEEE802154_NO_BEACON) {
					//asm("bgnd");
					call ConsoleOut.print("No beacon in scan :-(\n");
					//asm("bgnd");
				} else {
/*					call ConsoleOut.print("Unknown status: 0x");
					call ConsoleOut.printHex(status);
					call ConsoleOut.print("\n");*/
				}
				break;
			}
			// Orphan scan mode
			case IEEE802154_OrphanScan:
				if (status == IEEE802154_SUCCESS) {
				} else if (status == IEEE802154_NO_BEACON) {
				} else {
/*					call ConsoleOut.print("Unknown status: 0x");
					call ConsoleOut.printHex(status);
					call ConsoleOut.print("\n");*/
				}
//				call ConsoleOut.print("Orphan scan not implemented yet!");
				break;
    				
    			default:
/*				call ConsoleOut.print("MLME_SCAN.confirm on unknown scan type: ");
				call ConsoleOut.printHex(scanType);
				call ConsoleOut.print("\n");*/
      	};
      	call MlmeScanRequestConfirm.destroy(confirm);
      	prompt();
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
	async event result_t ConsoleIn.get(uint8_t data) {
		atomic console_data = data;
		post handleGet();
		return SUCCESS;
	}
	
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
		Mlme_ScanRequestConfirm request;
		// Activity scan, all channels, approximately 0.5 sec on each 
		// create the scan request
		call MlmeScanRequestConfirm.create(&request);
		call MlmeScanRequestConfirm.setScanType(request,IEEE802154_ActiveScan);
		call MlmeScanRequestConfirm.setScanChannels(request,0x07FFF800);
		call MlmeScanRequestConfirm.setScanDuration(request,6);
		
		if (call MlmeRequestConfirmScan.request(request))
		{
			DBG_STR("Starting active scan...",1);
		}
		else
		{
			DBG_STR("Could not start active scan...",1);
		}
	}
	
	task void pscan() {
		Mlme_ScanRequestConfirm request;
		// Passively scan all channels, approximately 0.5 sec on each 
		// create the scan request
		call MlmeScanRequestConfirm.create(&request);
		call MlmeScanRequestConfirm.setScanType(request,IEEE802154_PassiveScan);
		call MlmeScanRequestConfirm.setScanChannels(request,0x07FFF800);
		call MlmeScanRequestConfirm.setScanDuration(request,7);
		
		if (call MlmeRequestConfirmScan.request(request))
		{
			DBG_STR("Starting passive scan...",1);
		}
		else
		{
			DBG_STR("Could not start passive scan...",1);
		}
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
		Mlme_ScanRequestConfirm request; 
		// create the scan request
		call MlmeScanRequestConfirm.create(&request);
		call MlmeScanRequestConfirm.setScanType(request,IEEE802154_EDScan);
		call MlmeScanRequestConfirm.setScanChannels(request,0x07FFF800);
		call MlmeScanRequestConfirm.setScanDuration(request,5);
		
		if (call MlmeRequestConfirmScan.request(request))
		{
			DBG_STR("Starting energy detection scan...",1);
		}
		else
		{
			DBG_STR("Could not start energy detection scan...",1);
		}
	}
	
	task void sync()
	{
		Mlme_SyncRequest request;
		// just hardwire the relevant PIB attributes TODO: correct this
		macPanId = 0xDEFE; // accounting for endianness
		macCoordShortAddress = 0x0300; // accounting for endianness
		macBeaconOrder = 0x08;
		macSuperframeOrder = 0x08;
		macAutoRequest = FALSE;
		//PanID, Coordaddr, beaconorder,autorequest
		call MlmeSyncRequest.create(&request);
		call MlmeSyncRequest.setLogicalChannel( request, 11 );
		call MlmeSyncRequest.setTrackBeacon( request, TRUE );
		
		call MlmeRequestSync.request( request );
		DBG_STR("Requesting beacon synchronization",1);
	}
	
	/* ********************************************************************** */
	/** 
	 * Handle the result of a active or passive scan
	 *
 	*/
	/* ********************************************************************** */
	void scanTask()
	{
		uint8_t linkQuality,bestLinkQuality = 0;
		uint8_t i,listSize, theChannel;
		uint16_t sframeSpec, panId, beaconSpec;	

		Ieee_Address coordAddr;
		// Warning: we assume the requestbuffer still has the scan confirm msg.
		Ieee_PanDescriptor pd,bestPd = NULL;
		
		call IeeeAddress.create(&coordAddr);
		
		listSize = call MlmeScanRequestConfirm.getResultListSize(scanconfirm);
		DBG_STRINT("Number of results: ", listSize, 1);
		for (i = 0; i < listSize; i++) {
			pd = call MlmeScanRequestConfirm.getPanDescriptor(scanconfirm,i);
			call IeeePanDescriptor.getCoordAddr(pd, coordAddr);
			panId = call IeeeAddress.getPanId(coordAddr);
			sframeSpec = call IeeePanDescriptor.getSuperframeSpec(pd);
			theChannel = call IeeePanDescriptor.getLogicalChannel(pd);

			DBG_STRINT("Result #: ",i,1);
			DBG_STRINT("PAN ID: ",panId,1);
			DBG_STRINT("Channel: ",theChannel,1);

			// TODO: change this to be freescale independent
/*			if ( (sframeSpec & gSuperFrameSpecMsbAssocPermit_c) &&
			     (sframeSpec>>8 & gSuperFrameSpecLsbBO_c) == 0x7 ) {*/
			     linkQuality = call IeeePanDescriptor.getLinkQuality(pd);
				// Get the best
				if (linkQuality >= bestLinkQuality) {
					bestLinkQuality = linkQuality;
					bestPd = pd;
				}
//			}
		}

		// TODO: get rid of the pointer assumptions and the freescale stuff
		if (bestPd) {
			memcpy(panInfo, bestPd, sizeof(panDescriptor_t));
			DBG_STR("Found a link!",1);
			//This is where everything is A-OK.
		} else {
			DBG_STR("No best link?",1);
			return;
		}
		call IeeePanDescriptor.getCoordAddr(bestPd, coordAddr);
		DBG_STR("scan found coordinator:",1);
		DBG_STR("Address",1 ); 
		
		if (call IeeeAddress.getAddrMode(coordAddr) == 2) {
			DBG_DUMP(call IeeeAddress.getAddress(coordAddr), 2, 1);
		} else {
			DBG_DUMP(call IeeeAddress.getAddress(coordAddr), 8, 1);
		}
		
		panId = call IeeeAddress.getPanId(coordAddr);
		theChannel = call IeeePanDescriptor.getLogicalChannel(bestPd);
		beaconSpec = call IeeePanDescriptor.getSuperframeSpec(bestPd);
		
		DBG_STRINT("PAN ID: ",panId,1);
		DBG_STRINT("Logical Channel: ",theChannel,1);
		DBG_STRINT("Beacon Spec: ",beaconSpec,1);
		DBG_STRINT("Link Quality: ",bestLinkQuality,1);
		
		prompt();
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
	void edscanTask()
	{
		uint8_t n,minEnergy,listSize;
		// Set the minimum energy to a large value 
		minEnergy = 0xFF;
		// Select default channel 
		logicalChannel = 0;
		
		listSize = call MlmeScanRequestConfirm.getResultListSize(scanconfirm);
      
		// Search for the channel with least energy 
		for(n=11; n<11+listSize; n++) {
			uint8_t energy = call MlmeScanRequestConfirm.getEnergyDetectElement(scanconfirm, n);
			DBG_STRINT("Channel is:", n, 1);
			DBG_STRINT("Energy is:", energy, 1);
			if(energy < minEnergy) {
				minEnergy = energy;
				logicalChannel = n;
			}
		}
      
		// Channel numbering is 11 to 26 both inclusive 
		logicalChannel += 11;
		
		DBG_STR("Selected channel:",1);
		DBG_INT(logicalChannel,1);
		prompt();
	}
	
	/* **********************************************************************
	 * Handle stuff from the console
	 * *********************************************************************/
	 // Print a prompt.
	void prompt()
	{
		call ConsoleOut.print("[root@evb13192-");
		call ConsoleOut.printHexword(TOS_LOCAL_ADDRESS);
		call ConsoleOut.print(" /]# ");
	}

	/** Help function, does string compare */
	int strcmp(const char * a, const char * b)
	{
		while (*a && *b && *a == *b) { ++a; ++b; };
		return *a - *b;
	}
	
	/** Help function, does string compare */
	int strcmp2(const char * a, const char * b, uint8_t num)
	{
		uint8_t i = 1;
		while (*a && *b && *a == *b && i < num) { ++a; ++b; ++i; };
		return *a - *b;
	}
  
	int parseArg(const char* from)
	{
		int i = 1000;
		int num = 0;
		while(*from) {
			num = num + (i * (((unsigned int) *from) - 48));	
			i = i / 10;
			from++;
		} 
		return num;
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
		call ConsoleOut.print(console_transmit); 

		/* Check if enter was pressed */
		if (console_transmit[0] == 10) {
			/* If enter was pressed, "handle" command */
			if (0 == strcmp("ls", cmd_input)) {
				call ConsoleOut.print("ascan  pscan    doze    help  ls    setassoc  startpan  wake requestgts\n");
				call ConsoleOut.print("associate  edscan  info  send  setshort  time  disassoc\n");
				prompt();
			} else if (0 == strcmp("", cmd_input)) {
				prompt();
			} else if (0 == strcmp("ascan", cmd_input)) {
				post ascan();
			} else if (0 == strcmp("pscan", cmd_input)) {
				post pscan();
			} else if (0 == strcmp("edscan", cmd_input)) {
				post edscan();
			} else if (0 == strcmp("rxon", cmd_input)) {
				post rxOnTask();
			} else if (0 == strcmp("testtx", cmd_input)) {
				post testTxTask();		
			} else if (0 == strcmp("sync", cmd_input)) {
				post sync();
			} else {
				call ConsoleOut.print("tosh: ");
				call ConsoleOut.print(cmd_input);
				call ConsoleOut.print(": command not found\n");
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
}
