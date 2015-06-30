//#include <FreescaleAdts.h>
#include <macTypes.h>

module TestMainM {
	provides {
		interface StdControl;
	}
	uses {
		interface Freescale802154Control as Control;

	    interface IeeeMacPibAttribute as IeeePibAttribute;
		interface IeeePanDescriptor;
		interface IeeeMacSdu as IeeeSdu;
	   
		interface McpsDataIndication;
		interface McpsDataRequestConfirm;
	
		interface MlmeAssociateIndicationResponse; 
		interface MlmeAssociateRequestConfirm;
		interface MlmeGtsIndication;
		interface MlmeGtsRequestConfirm;
		interface MlmeScanRequestConfirm;
		interface MlmeSetRequestConfirm;
		interface MlmeStartRequestConfirm;
		interface MlmeSyncLossIndication;

		// MCPS
		interface IeeeIndication<Mcps_DataIndication> as McpsIndicationData;   	
		interface IeeeRequestConfirm<Mcps_DataRequestConfirm> as McpsRequestConfirmData;   	
		// MLME	
		interface IeeeIndicationResponse<Mlme_AssociateIndicationResponse> as MlmeIndicationResponseAssociate;
		interface IeeeRequestConfirm<Mlme_AssociateRequestConfirm> as MlmeRequestConfirmAssociate;
		interface IeeeIndication<Mlme_GtsIndication> as MlmeIndicationGts;
		interface IeeeRequestConfirm<Mlme_GtsRequestConfirm> as MlmeRequestConfirmGts;
		interface IeeeRequestConfirm<Mlme_ScanRequestConfirm> as MlmeRequestConfirmScan;
		interface IeeeRequestConfirm<Mlme_SetRequestConfirm> as MlmeRequestConfirmSet;
		interface IeeeRequestConfirm<Mlme_StartRequestConfirm> as MlmeRequestConfirmStart;
		interface IeeeIndication<Mlme_SyncLossIndication> as MlmeIndicationSyncLoss;
		interface ConsoleInput as ConsoleIn;
		interface ConsoleOutput as ConsoleOut;
		interface Leds;
	}
}
implementation
{  
  	// Message for passing to the asp layer, allocated here, to not break the stack.
	aspMsg_t msg;
	
	// buffer for building requests
/*	#define MLMEREQUESTBUFFERSIZE sizeof(MlmeRequestConfirm_t)
	#define MCPSREQUESTBUFFERSIZE sizeof(McpsRequestConfirm_t)
	#define MLMEINDICATIONBUFFERSIZE sizeof(MlmeIndicationResponse_t)
	#define MCPSINDICATIONBUFFERSIZE sizeof(McpsIndication_t)
	#define PIBATTRIBUTEBUFFERSIZE 100
	#define MSDUSNDBUFFERSIZE 20
	#define MSDURCVBUFFERSIZE 200

	char mlmeRequestBuffer[MLMEREQUESTBUFFERSIZE];
	char mcpsRequestBuffer[MCPSREQUESTBUFFERSIZE];
	// buffer for setting pib attributes
	char pibAttributeBuffer[PIBATTRIBUTEBUFFERSIZE];	
	// buffer for indications. TODO: protect it properly
	char mlmeIndicationBuffer[MLMEINDICATIONBUFFERSIZE];
	char mcpsIndicationBuffer[MCPSINDICATIONBUFFERSIZE];
	char msduSndBuffer[MSDUSNDBUFFERSIZE];
	char msduRcvBuffer[MSDURCVBUFFERSIZE];*/
			
	Ieee_Msdu sendMsdu;
	Ieee_Msdu rcvMsdu;
	
	// The selected logical channel is store in here, initialized to 11
	uint8_t logicalChannel = 11;
	uint8_t *EDList;

	// Global variable used for activty -> association (Yes, ugly, fix it :-)
	Mlme_ScanRequestConfirm scanconfirm;
	panDescriptor_t panInfo;
	
	/* Testing doze */
	bool_t weAreDozing = FALSE;

	/** Short address we got */
	uint16_t panClientShort;

	/** Used to keep the commands the user type in */
	char cmd_input[200];
	char * bufpoint;

	/** Store data from the Console.get event here. */
	char console_data;

	void prompt();
	task void ascan();
	task void pscan();
	void scanTask();
	task void help();
	task void info();
	task void requestGts();
	task void startpan();
	task void setshort();
	int strcmp(const char * a, const char * b);
	task void handleGet();
 
	command result_t StdControl.init()
	{
		char* testBuffer = "Hello World!";
		char* dst;
		/* Just make sure that something happens. */
//		call Leds.init();
//		call Leds.redOn();

		/* Set up our command buffer */
		bufpoint = cmd_input;
		*bufpoint = 0;


		/* Other init */
		call Control.init();
	/*	if (!call Control.init()) {
			// call Console.print("\nError initalizing Freescale Mac Layer!\n");
			call Leds.yellowOn();
		} else {
			 call Console.print("\n\rTestMainM.nc (802.15.4) booted\n\r");
			call Leds.greenOn();
		}*/
		// TODO: Reinitialize timers after Control have been initialized?
		
		// load hello world into our testMsdu
		call IeeeSdu.create(12,&sendMsdu);
		dst = call IeeeSdu.getPayload(sendMsdu);
		memcpy(dst,testBuffer,13);
		
		return SUCCESS;
	}

	command result_t StdControl.start() { 
		prompt();
		return SUCCESS; //call Timer.start(TIMER_REPEAT, 1000);
	}

	command result_t StdControl.stop()
	{
		return FAIL; //call Timer.stop(); 
	}
	
/*	event Mcps_DataIndication McpsIndicationData.prepareIndication()
	{
		Mcps_DataIndication indication;
		// prepare the rcvMsdu
		call IeeeSdu.create(msduRcvBuffer,200,&rcvMsdu);		
		if (!call McpsDataIndication.create(mcpsIndicationBuffer,MCPSINDICATIONBUFFERSIZE,rcvMsdu,&indication))
		{
			call ConsoleOut.print("McpsIndicationData.prepareIndication: creation error\n");
		}
		call ConsoleOut.print("Preparing data indication\n");
		return indication;
	}*/
	
	event void McpsIndicationData.indication(Mcps_DataIndication indication)
	{
		Ieee_Msdu msdu = call McpsDataIndication.getMsdu(indication);
		char* buffer = call IeeeSdu.getPayload(msdu);
		call ConsoleOut.print("Got data indication:\n");
		call ConsoleOut.print(buffer);
		call ConsoleOut.print("\n");
		prompt();
		call McpsDataIndication.destroy(indication);
	}
	
	event void McpsRequestConfirmData.confirm( Mcps_DataRequestConfirm confirm )
	{
		Ieee_Status status;
		status = call McpsDataRequestConfirm.getStatus(confirm);
		if ( status != 0 )
		{
			call ConsoleOut.print("McpsRequestConfirmData.confirm FAILURE \n");
		}
		else
		{
			call ConsoleOut.print("McpsRequestConfirmData.confirm SUCCESS \n");
		}
		prompt();
		call McpsDataRequestConfirm.destroy(confirm);
	}
	
	
/*	event Mlme_AssociateIndicationResponse MlmeIndicationResponseAssociate.prepareIndication()
	{
		Mlme_AssociateIndicationResponse indication;
		call MlmeAssociateIndicationResponse.create(mlmeIndicationBuffer,MLMEINDICATIONBUFFERSIZE,&indication);
		return indication;
	}
	
	event void MlmeIndicationResponseAssociate.responseDone( Mlme_AssociateIndicationResponse response )
	{
		call ConsoleOut.print("Got MlmeIndicationResponseAssociate.responseDone\n ");
		return;
	}*/
	
	event void MlmeIndicationSyncLoss.indication( Mlme_SyncLossIndication indication)
	{
	
	}
	
	event void MlmeIndicationResponseAssociate.indication( Mlme_AssociateIndicationResponse indication )
	{
		uint64_t deviceAddress = call MlmeAssociateIndicationResponse.getDeviceAddress(indication);
		call ConsoleOut.print("Device is at ");
		call ConsoleOut.dumpHex((uint8_t *)&deviceAddress, 8, "");
		call ConsoleOut.print("\n");

		call MlmeAssociateIndicationResponse.setDeviceAddress(indication,deviceAddress);
		call MlmeAssociateIndicationResponse.setAssocShortAddress(indication,0xDEAD);
		call MlmeAssociateIndicationResponse.setStatus(indication,0);
		call MlmeAssociateIndicationResponse.setSecurityEnable(indication,FALSE);
		call MlmeIndicationResponseAssociate.response(indication);
		prompt();
	}
	
	event void MlmeRequestConfirmAssociate.confirm(Mlme_AssociateRequestConfirm confirm)
	{
		Ieee_Status status = call MlmeAssociateRequestConfirm.getStatus(confirm);
		panClientShort = call MlmeAssociateRequestConfirm.getAssocShortAddress(confirm);
		call ConsoleOut.print("MlmeRequestConfirmAssociate.confirm, check status and address\n");
		call ConsoleOut.print("Short address: 0x");
		call ConsoleOut.printHexword(panClientShort);
		call ConsoleOut.print(", status: 0x");
		call ConsoleOut.printHex(status);
		call ConsoleOut.print("\n");
		call MlmeAssociateRequestConfirm.destroy(confirm);
	}
	
/*	event Mlme_GtsIndication MlmeIndicationGts.prepareIndication()
	{
		Mlme_GtsIndication indication;
		call MlmeGtsIndication.create(mlmeIndicationBuffer,MLMEINDICATIONBUFFERSIZE,&indication);
		return indication;
	}*/
  
  	event void MlmeRequestConfirmGts.confirm(Mlme_GtsRequestConfirm confirm)
  	{
  		Ieee_Status status = call MlmeGtsRequestConfirm.getStatus(confirm);
  		call ConsoleOut.print("MlmeRequestConfirmGts.confirm, status ");
		call ConsoleOut.printHex(status);
		call ConsoleOut.print("\n");
  		prompt();
  		call MlmeGtsRequestConfirm.destroy(confirm);
  	}
  	
  	event void MlmeIndicationGts.indication( Mlme_GtsIndication indication )
  	{
  		call ConsoleOut.print("MlmeRequestConfirmGts.indication\n ");
  		prompt();
  		call MlmeGtsIndication.destroy(indication);
  	}
  	
	event void MlmeRequestConfirmSet.confirm(Mlme_SetRequestConfirm confirm)
	{		
		switch(call MlmeSetRequestConfirm.getPibAttribute(confirm)) {
			case IEEE802154_macShortAddress:
				call ConsoleOut.print("MLME_SET.confirm for macShortAddress\n");
				break;
      
			case IEEE802154_macAssociationPermit:
				call ConsoleOut.print("MLME_SET.confirm for macAssociationPermit\n");
				break;

			default:
				call ConsoleOut.print("Unknown PIB set");
		};
		call MlmeSetRequestConfirm.destroy(confirm);
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
 			case gScanModeED_c: {
				
 				if (status != gSuccess_c) {
 					break;
 				}
// 				EDList = EnergyDetectList;
//				post edscanTask();
				break;
			}
			// Active Scan
			case gScanModeActive_c: {
				
				/* Check status */
				if (status == ASUCCESS) {
//					call ConsoleOut.print("Active scan successful\n");
					if (resultListSize == 0) {
						call ConsoleOut.print("No results!\n");
						break;
					}
					
					scanconfirm = confirm;
					
					scanTask();

				} else if (status == NO_BEACON) {
					//asm("bgnd");
					call ConsoleOut.print("No beacon in active scan :-(\n");
					//asm("bgnd");
				} else {
/*					call ConsoleOut.print("Unknown status: 0x");
					call ConsoleOut.printHex(status);
					call ConsoleOut.print("\n");*/
				}
				break;
			}
			// Passive scan mode
			case gScanModePassive_c:
				if (status == gSuccess_c) {
					if (resultListSize == 0) {
						call ConsoleOut.print("No results!\n");
						break;
					}
				}
				else
				{
					break;
				}
				scanconfirm = confirm;
				scanTask();
				
				break;

			// Orphan scan mode
			case gScanModeOrphan_c:
				if (status == gSuccess_c) {
				} else if (status == gNoBeacon_c) {
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
	}
	
	event void MlmeRequestConfirmStart.confirm(Mlme_StartRequestConfirm confirm)
	{
		Ieee_Status status = call MlmeStartRequestConfirm.getStatus(confirm);
		call ConsoleOut.print("MLME_START.confirm, status: 0x");
		call ConsoleOut.printHex(status);
		call ConsoleOut.print("\n");
		call MlmeStartRequestConfirm.destroy(confirm);
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
		call Leds.redToggle();
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
		call MlmeScanRequestConfirm.setScanType(request,gScanModeActive_c);
		call MlmeScanRequestConfirm.setScanChannels(request,0x07FFF800);
		call MlmeScanRequestConfirm.setScanDuration(request,5);
		
		if (call MlmeRequestConfirmScan.request(request))
		{
			call ConsoleOut.print("Starting active scan...\n");
		}
		else
		{
			call ConsoleOut.print("Could not start active scan...\n");
		}
	}
	
	task void pscan() {
		Mlme_ScanRequestConfirm request;
		// Passively scan all channels, approximately 0.5 sec on each 
		// create the scan request
		call MlmeScanRequestConfirm.create(&request);
		call MlmeScanRequestConfirm.setScanType(request,gScanModePassive_c);
		call MlmeScanRequestConfirm.setScanChannels(request,0x07FFF800);
		call MlmeScanRequestConfirm.setScanDuration(request,7);
		
		if (call MlmeRequestConfirmScan.request(request))
		{
			call ConsoleOut.print("Starting passive scan...\n");
		}
		else
		{
			call ConsoleOut.print("Could not start passive scan...\n");
		}
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
		uint8_t i,listSize;
		uint16_t sframeSpec;
		uint64_t coordAddress;
		// Warning: we assume the requestbuffer still has the scan confirm msg.
		Ieee_PanDescriptor pd,bestPd = NULL;
		listSize = call MlmeScanRequestConfirm.getResultListSize(scanconfirm);
		call ConsoleOut.print("Examining \n");
		call ConsoleOut.printHex(listSize);
		call ConsoleOut.print(" results\n");
		for (i = 0; i < listSize; i++) {
			pd = call MlmeScanRequestConfirm.getPanDescriptor(scanconfirm,i);
			sframeSpec = call IeeePanDescriptor.getSuperframeSpec(pd);

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
			memcpy(&panInfo, bestPd, sizeof(panDescriptor_t));
			call ConsoleOut.print("Found a link!\n");
			//This is where everything is A-OK.
		} else {
			call ConsoleOut.print("No best link?\n");
			return;
		}
		call ConsoleOut.print("scan found coordinator:\n");
		call ConsoleOut.print("Address 0x"); 
		coordAddress = call IeeePanDescriptor.getCoordAddress(bestPd);
		
		call ConsoleOut.dumpHex((uint8_t*)&coordAddress, 8, "");
		
		call ConsoleOut.print("\nPAN ID 0x");
		call ConsoleOut.printHexword(call IeeePanDescriptor.getCoordPanId(bestPd));
    
		call ConsoleOut.print("\nLogical Channel 0x"); 
		call ConsoleOut.printHex(call IeeePanDescriptor.getLogicalChannel(bestPd));
    
		call ConsoleOut.print("\nBeacon Spec 0x"); 
		call ConsoleOut.printHexword(call IeeePanDescriptor.getSuperframeSpec(bestPd));
    
		call ConsoleOut.print("\nLink Quality 0x"); 
		call ConsoleOut.printHex(call IeeePanDescriptor.getLinkQuality(bestPd));
		call ConsoleOut.print("\n");
		prompt();
	}
	
	/* ********************************************************************** */
	/**
	 * Associate to a pan.
	 *
	 * <p>Use the value found in ascan to associate to a PAN</p>
	 */
	/* ********************************************************************** */
	task void associate() __attribute__((noinline))
	{
		Mlme_AssociateRequestConfirm request;
		call MlmeAssociateRequestConfirm.create(&request);
		call MlmeAssociateRequestConfirm.setLogicalChannel(request,panInfo.logicalChannel);
		call MlmeAssociateRequestConfirm.setCoordInfo( request,
		                                               call IeeePanDescriptor.getCoordAddrMode(&panInfo),
		                                               call IeeePanDescriptor.getCoordAddress(&panInfo),
		                                               call IeeePanDescriptor.getCoordPanId(&panInfo));
		                                             
		call MlmeAssociateRequestConfirm.setCapabilityInformation(request,gCapInfoAllocAddr_c);
		call MlmeAssociateRequestConfirm.setSecurityEnable(request,FALSE);
		if (call MlmeRequestConfirmAssociate.request(request))
		{
			call ConsoleOut.print("Associating to PAN... \n");
		}
		else
		{
			call ConsoleOut.print("Could not request association to PAN... \n");
			prompt();
		}
	}
	
	task void requestGts()
	{
		Mlme_GtsRequestConfirm request;
		
		call MlmeGtsRequestConfirm.create(&request);
		call MlmeGtsRequestConfirm.combineGtsCharacteristics(request,1,0,1);
		call MlmeGtsRequestConfirm.setSecurityEnable(request,FALSE);
		
		if (call MlmeRequestConfirmGts.request(request))
		{
			call ConsoleOut.print("Requesting guaranteed timeslot... \n");
		}
		else
		{
			call ConsoleOut.print("Could not request guaranteed timeslot... \n");
			prompt();
		}
	}
	
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
		uint64_t SrcAddr;
		uint16_t coPanId;
		Mcps_DataRequestConfirm request;

		if (panClientShort == 0xFFEE) {
			call ConsoleOut.print("Sending using extended address\n");
			SrcAddrMode = 3;
			memcpy((void *) &SrcAddr, (void *) aExtendedAddress, 8);
		} else {
			call ConsoleOut.print("Sending using short address\n");
			SrcAddrMode = 2;
			memcpy((void *) &SrcAddr, (void *) &panClientShort, 2);
		}
		coPanId = call IeeePanDescriptor.getCoordPanId(&panInfo);
    

    	// Create request
    	
		call McpsDataRequestConfirm.create(&request);    	
		call McpsDataRequestConfirm.setSrcInfo( request,
		                                        SrcAddrMode,
		                                        SrcAddr,
		                                        coPanId );		                                        
		call McpsDataRequestConfirm.setDstInfo( request,
    	                                        call IeeePanDescriptor.getCoordAddrMode(&panInfo),
    	                                        call IeeePanDescriptor.getCoordAddress(&panInfo),
    	                                        coPanId );    	                                        
		call McpsDataRequestConfirm.setMsdu( request, sendMsdu, 0x42 );
		// TODO: change to non-Freescale const
		call McpsDataRequestConfirm.setTxOptions( request, gTxOptsAck_c );

		call McpsRequestConfirmData.request(request);
	}
	
	
	/* ********************************************************************** */
	/**
	 * Setting the short addres.
	 *
	 * <p>Sets the short address to TOS_LOCAL_ADDRESS, by calling </p>
	 */
	/* ********************************************************************** */
	task void setshort() {
		Mlme_SetRequestConfirm request;
		Ieee_PibAttribute attribute;
		call IeeePibAttribute.create(2,&attribute);
		call IeeePibAttribute.setMacShortAddress(attribute,TOS_LOCAL_ADDRESS);
		
		call MlmeSetRequestConfirm.create(&request);
		call MlmeSetRequestConfirm.setPibAttribute(request,attribute);
	
		if ( call MlmeRequestConfirmSet.request(request) )
		{
			call ConsoleOut.print("Setting short address...\n");
		}
		else
		{
			call ConsoleOut.print("Failed to set short address...\n");
		}
 		prompt();
	}
	
	/* ********************************************************************** */
	/**
	 * Set the association status
	 *
	 * <p>This PIB setting must be set after starting the PAN.</p>
	 */
	/* ********************************************************************** */
 
	task void setassoc() {
		Mlme_SetRequestConfirm request;
		Ieee_PibAttribute attribute;
		call IeeePibAttribute.create(1,&attribute);
		call IeeePibAttribute.setMacAssociationPermit(attribute,TRUE);
		
		call MlmeSetRequestConfirm.create(&request);
		call MlmeSetRequestConfirm.setPibAttribute(request,attribute);
	
	
		if (call MlmeRequestConfirmSet.request(request))
		{
			call ConsoleOut.print("Setting association bit\n");
		}
		else
		{
			call ConsoleOut.print("Set request failed\n");
		}
		prompt();
	}
	
	task void setBsd() {
		Mlme_SetRequestConfirm request;
		Ieee_PibAttribute attribute;
		call IeeePibAttribute.create(1,&attribute);
		call IeeePibAttribute.setMacAssociationPermit(attribute,TRUE);
		
		call MlmeSetRequestConfirm.create(&request);
		call MlmeSetRequestConfirm.setPibAttribute(request,attribute);
	
	
		if (call MlmeRequestConfirmSet.request(request))
		{
			call ConsoleOut.print("Setting association bit\n");
		}
		else
		{
			call ConsoleOut.print("Set request failed\n");
		}
		prompt();
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
		Mlme_StartRequestConfirm request;
		call MlmeStartRequestConfirm.create(&request);
		// Note, that the panid should not be hardcoded... :-)
		call MlmeStartRequestConfirm.setPanId(request,0xBEEF);
		call MlmeStartRequestConfirm.setLogicalChannel(request,11);
		call MlmeStartRequestConfirm.setBeaconOrder(request,0x0F); // beacon often
		call MlmeStartRequestConfirm.setSuperframeOrder(request,0x0F); // superframe often
		call MlmeStartRequestConfirm.setPanCoordinator(request,TRUE);
		call MlmeStartRequestConfirm.setBatteryLifeExtension(request,FALSE);
		call MlmeStartRequestConfirm.setCoordRealignment(request,FALSE);
		call MlmeStartRequestConfirm.setSecurityEnable(request,FALSE);
		if ( call MlmeRequestConfirmStart.request(request) )
		{
			call ConsoleOut.print("Starting PAN as coordinator...\n");
		}
		else
		{
			call ConsoleOut.print("Failed to start PAN...\n");
		}
		
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
		call ConsoleOut.print("Try ls\n");
		call ConsoleOut.print("To become PAN coordinator: setshort -> startpan -> setassoc\n");
		call ConsoleOut.print("To join a PAN network: ascan -> associate -> send \n");
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
		call ConsoleOut.print("Node 0x");
		call ConsoleOut.printHexword(TOS_LOCAL_ADDRESS);
		call ConsoleOut.print(" has MAC extended address (broken, perhaps NV_RAM?)");
		call ConsoleOut.dumpHex(aExtendedAddress, 8, "");
		call ConsoleOut.print("\n");
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
	//	call Leds.greenToggle();
		call ConsoleOut.print(console_transmit); 

		/* Check if enter was pressed */
		if (console_transmit[0] == 10) {
			/* If enter was pressed, "handle" command */
			if (0 == strcmp("ls", cmd_input)) {
				call ConsoleOut.print("ascan  pscan    doze    help  ls    setassoc  startpan  wake requestgts\n"
				                   "associate  edscan  info  send  setshort  time  disassoc\n");
			   prompt();
			} else if (0 == strcmp("", cmd_input)) {
				prompt();
			} else if (0 == strcmp("associate", cmd_input)) {
				post associate();
			} else if (0 == strcmp("ascan", cmd_input)) {
				post ascan();
			} else if (0 == strcmp("pscan", cmd_input)) {
				post pscan();
			} else if (0 == strcmp("doze", cmd_input)) {
//				post doze();
			} else if (0 == strcmp("edscan", cmd_input)) {
//				post edscan();
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
//				post disassoc();
			} else if (0 == strcmp("startpan", cmd_input)) {
				post startpan();
			} else if (0 == strcmp("time", cmd_input)) {
//				post getTime();
			} else if (0 == strcmp("wake", cmd_input)) {
//				post getWake();
			} else if (0 == strcmp("get", cmd_input)) {
//				post testGet();
			} else if (0 == strcmp("requestgts", cmd_input)) {
				post requestGts();
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
/*	task void getTime()
	{
		msg.msgType = gAppAspGetTimeReq_c;
		if (gSuccess_c != MSG_Send(APP_ASP, &msg)) {
			call ConsoleOut.print("Error calling MSG_Send\n");
		} else {
			call ConsoleOut.print("0x");
			call ConsoleOut.printHex(msg.aspToAppMsg.msgData.appGetTimeCfm.time[2]);
			call ConsoleOut.printHex(msg.aspToAppMsg.msgData.appGetTimeCfm.time[1]);
			call ConsoleOut.printHex(msg.aspToAppMsg.msgData.appGetTimeCfm.time[0]);
			call ConsoleOut.print("\n");
		}
		prompt();
	}*/

	/* ********************************************************************** */
	/**
	 * Task that request a wake.
	 *
	 * <p>Broken, I think.</p>
	 */
	/* ********************************************************************** */
/*	task void getWake()
	{
		msg.msgType = gAppAspWakeReq_c;
		if (gSuccess_c == MSG_Send(APP_ASP, &msg)) {
			call ConsoleOut.print("Wake requested\n");
		} else {
			call ConsoleOut.print("Error calling MSG_Send\n");
		}
		prompt();
	}*/

	/////
	// Functions testing MLME_SCAN Interface.
	////////
	

	/* ********************************************************************** */
	/** Post an energy detection scan, that is, talk to the MLME layer.
	 *
	 * <p>Scans all channels, as indicated by the 0x07FFFF800 bit mask,
	 * each channel is scanned for approximately 0.5 seconds (indicated
	 * by the 5, note, there is a non linear relation between 0.5 secs
	 * and 5).</p> 
	 */
	/* ********************************************************************** */
/*	task void edscan()
	{
		// Energy scan, all channels, approximately 0.5 sec on each 
		call ConsoleOut.print("Starting energy detection scan ...");
		call MLME_SCAN.request(gScanModeED_c, 0x07FFF800, 5);
	}*/

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
/*	task void edscanTask()
	{
		uint8_t n,minEnergy;
		// Set the minimum energy to a large value 
		minEnergy = 0xFF;
		// Select default channel 
		logicalChannel = 0;
      
		// Search for the channel with least energy 
		for(n=0; n<16; n++) {
			if(EDList[n] < minEnergy) {
				minEnergy = EDList[n];
				logicalChannel = n;
			}
		}
      
		// Channel numbering is 11 to 26 both inclusive 
		logicalChannel += 11;
		
		call ConsoleOut.print("Selected channel ");
		call ConsoleOut.printHex(logicalChannel);
		call ConsoleOut.print("\n"); 
		prompt();
	}*/



	

	// Functions used to start a PAN coordinator.









	// Functions for testing association and disassociation.

/*	task void disassoc()
	{
		call ConsoleOut.print("Disassociating from PAN ... ");
		call MLME_DISASSOCIATE.request(*((uint64_t*)panInfo.coordAddress),2,FALSE);
	}*/

	/* ********************************************************************** */
	/**
	 * Respond to an association request.
	 *
	 * <p>For now, just print a message.</p>
	 */
	/* ********************************************************************** */
/*	event void MLME_DISASSOCIATE.indication(uint64_t DeviceAddress,
	                                        IEEE_status DisassociateReason,
	                                        bool SecurityUse,
	                                        uint8_t ACLEntry)
	{
		call ConsoleOut.print("MLME_DISASSOCIATE.indication\n");
		call ConsoleOut.print("Device is at ");
		call ConsoleOut.dumpHex((uint8_t *)&DeviceAddress, 8, "");
		call ConsoleOut.print("\n");
	}*/
  
	/* ********************************************************************** */
	/**
	 * We got associated.
	 *
	 * <p>For now, just print a message.</p>
	 */
	/* ********************************************************************** */
/*	event void MLME_DISASSOCIATE.confirm(IEEE_status status)
	{
		call ConsoleOut.print("MLME_DISASSOCIATE.confirm, check status\n");
		call ConsoleOut.print("status: 0x");
		call ConsoleOut.printHex(status);
		call ConsoleOut.print("\n");
	}*/

  
/*	event void MLME_GET.confirm(IEEE_status status, uint8_t pibAttribute, void *pibAttributeValue)
	{
		call ConsoleOut.print("MLME_GET.confirm:\n");
		call ConsoleOut.print("Result was: 0x");
		call ConsoleOut.printHex(*(uint8_t*)pibAttributeValue);
		call ConsoleOut.print("\n");
	}*/

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
  
/*	task void testGet()
	{
		call MLME_GET.request(gMacRole_c);  
	} */

	// Functions used to test sending data over the radio.

	
	/* **********************************************************************
	 * Broken handlers
	 * *********************************************************************/


	/* ********************************************************************** */
	/** Testing doze mode. Now, this is tricky, keep tounge in cheek

	    One would probably want to move this (and other calls to the ASP
	    interface) into the control interface. 

	    What to do about the needed stop code (if we want to powersave?
	    Does TinyOS have a power management API we should support, or is
	    it only AMStandard that have that?
	*/
  
	/*task void doze()
	{
		aspDozeReq_t * pDozeReq;
    
		// Normally we would check for data before going into doze, see PTC demo.
		// Set the type
		msg.msgType = gAppAspDozeReq_c;
    
		// Convenient pointer...
		pDozeReq = &msg.appToAspMsg.msgData.aspDozeReq;

		// This duration is about 5 seconds. 
		pDozeReq->dozeDuration[0] = 0xB4;
		pDozeReq->dozeDuration[1] = 0xC4;
		pDozeReq->dozeDuration[2] = 0x04;
    
		if (gSuccess_c != MSG_Send(APP_ASP, &msg)) {
			call ConsoleOut.print("Error calling MSG_Send\n");
			prompt();
			return;
		}
		if (msg.aspToAppMsg.msgData.appDozeCfm.status != gSuccess_c) {
			call ConsoleOut.print("Error, no doze!\n");
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
/*			SOPT |= 0x20; SPMSC2 &= ~0x02; __asm("STOP");
		}
		// NOTE: We should check the return values/status call
		prompt();
	}



} /* End of compoment */
