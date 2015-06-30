/* $Id: Freescale802154M.nc,v 1.1 2005/10/12 15:01:42 janflora Exp $ */
/* SimpleMac module. Wrapper around Freescale SMAC library.

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


/** Define a lot of Freescale structs and types... 
*/ 
// NOTE: Currently this is hacked into tos/system/tos.h
// includes PublicConst;
// includes DigiType;
// includes NwkMacInterface;
// includes PhyMacMsg;


/** 
 * Freescale 802.15.4 module.
 * 
 * <p>Provides an implementation of the Freescale 802.15.4
 * interface. The interfaces implemented by this modules is the TinyOS
 * 802.15.4 interfaces, slightly modified to support error
 * codes. Check the interface file for documentation.</p>
 *
 * <p>The overall structure is that the varios commands are implemented first, 
 * then the callback handlers, which issues any relevant signals.</p>
 *
 * <p>The Console and Led modules are assumed to be
 * initialized/started externally.</p>
 *
 * <p>Note that the initialization and clock setup is heavily
 * influenced by assumptions made by the Freescale
 * libraries. Apparently we must be running a stable 8 MHz clock
 * before we can initialize the stacks. We then need to provide a
 * callback function for the PHY library, that must be named
 * ICG_Setup. In here we should set up the clock to use the clock from
 * the radio. When the radio goes to doze mode, we lose the clock,
 * and get an interrupt. This should also be handled in
 * ICG_Setup. Check the comments to ICG_Setup. 
 *
 * <p>BIG TODO: Error handling!</p>
 *
 * <p>Even more major todo: Use the queues to handle messages? Look in
 * the MAX/PHY User Guide, section 3.2.1, last part.</p>
 *
 * <p>And, yet another TODO: The memory handling related to the msg
 * (MSG_Alloc, MSG_Free), is not at all tested. In some cases we
 * should not free stuff, in others we should. There does not seem to
 * be any tables or similar to describe this.</p>
 *
 * @author Mads Bondo Dydensborg <madsdyd@diku.dk>
 */

// Some ICG module bit positions, that we need in ICG_Setup.
#define ICG_IRQ_PENDING	0x01
#define ICG_FLL_LOCKED	0x08

module Freescale802154M {
	provides {
		interface Freescale802154Control as Control;
		interface MLME_GET;
		interface MLME_SCAN;
		interface MLME_START;
		interface MLME_SET;
		interface MLME_ASSOCIATE;
		interface MLME_DISASSOCIATE;
		interface MCPS_DATA;
	}
	uses {
		interface Console;
		interface Leds;
	}
}
implementation
{

	anchor_t MlmeNwkInputQueue;
	
	task void processMlmeNwk();
	void nwkScanCnf(nwkMessage_t *msg);
	void nwkDisassocInd(nwkMessage_t *msg);
	void nwkDisassocCnf(nwkMessage_t *msg);
	void nwkStartCnf(nwkMessage_t *msg);
	void nwkAssocInd(nwkMessage_t *msg);
	void nwkAssocCnf(nwkMessage_t *msg);
	void nwkCommStatusInd(nwkMessage_t *msg);

	/* ********************************************************************** */
	/**
	 * The purpose of the NV ram struct is still not entirely clear to
	 * me. However, it seems that we need to have this structure, if for
	 * no other purpose, then to allow the MAC layer to get a MAC
	 * address... The original Freescale software use it for a lot more
	 * than we do. */

	// TODO: We can only run with a busspeed of 16 - (32 MHz CPU) 
	// TODO: Does this need to be volatile??? const??? static???
	/* ********************************************************************** */
	// const 
	NV_RAM_Struct_t My_NV_RAM = {
		"Freescale_Copyright",
		"Firmware_Database_Label",
		"MAC_Version",
		"PHY_Version",
		"TinyOS 802.15.4 Console Test",
		{
			0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,
			0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,
			0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,
			0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,
			0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,
			0xFF,0xFF
		},      // FreeLoader_Firmware_Version
		0x0001, // NV_RAM_Version
		0x00,   // MCU_Manufacture
		0x02,   // MCU_Version
#define BUS_CLOCK_SEEMS_TO_BE_16
#ifdef BUS_CLOCK_SEEMS_TO_BE_8
		0x08,   // 8 MHz
		0x3645, // Abel_Clock_Out_Setting
		(ABEL_CCA_ENERGY_DETECT_THRESHOLD | 
		 ABEL_POWER_COMPENSATION_OFFSET), // Abel_HF_Calibration
		0x18, // NV_ICGC1
		0x00, // NV_ICGC2 // 0x00 => CPU clk=16 MHz, Buc clk = 8 MHz
		0x02, // NV_ICGFLTU (filtering)
		0x40, // NV_ICGFLTL (filtering)
		0x00, // NV_SCI1BDH
		0x1A, // NV_SCI1BDL 1A => 19200 @ 8 MHz
#endif /* BUS_CLOCK_SEEMS_TO_BE_16 */
#ifdef BUS_CLOCK_SEEMS_TO_BE_16
		0x10, // 16 MHz
		0x3645,
		(ABEL_CCA_ENERGY_DETECT_THRESHOLD |
		 ABEL_POWER_COMPENSATION_OFFSET),
		0x18,
		0x20, // 0x20 => CPU clk=32 MHz, Buc clk = 16 MHz
		0x02,
		0x40,
		0x00,
		0x34, // 0x34 => 19200 @ 16 MHz
#endif /* BUS_CLOCK_SEEMS_TO_BE_16 */
		// {0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF}, // MAC_Address
		{0x00,0x50,0xC2,0x37,0xB0,0x01,0x03,0x38}, // MAC_Address
		0x00, // AntennaSelect
		0x00, // SleepModeEnable
		{
			0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,
			0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF
		}, // HWName_Revision
		{
			0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF
		}, // Serialnumber
		0xFFFF, // ProductionSite
		0xFF,   // CountryCode
		0xFF,   // ProductionWeekCode
		0xFF,   // ProductionYearCode
		{
			0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,
			0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,
			0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,
			0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,
			0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,
			0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,
			0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,
			0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,
			0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,
			0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,
			0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,
			0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,
			0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,
			0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,
			0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,
			0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,
			0xFF,0xFF,0xFF
		}, // Application_Section
		NV_SYSTEM_FLAG // System flag, not to be changed
	};

	/* ********************************************************************** */
	/**
	 * Setup the clock.
	 *
	 * <p>This procedure sets up the clock. It can handle two cases. The
	 * "normal" case is when we wish to use the clock supplied by the
	 * radio. The other case, is when we have asked the radio to
	 * doze. In that case, we loose our clock, which triggers an
	 * interrupt. The interrupt handler will call this function, which
	 * will change to a 2MHZ clock. The intention is that the client
	 * requesting a doze mode from the radio, should ask the ASP layer
	 * for a temporary doze, then put the CPU into stop mode. </p>
	 */
	/* ********************************************************************** */
	/* Callback from interrupts, typically */
	void ICG_Setup() __attribute__((C, spontaneous))
	{
		uint8_t loopCounter;
		//    asm("bgnd"); // For the debugger.

		/** The NV_RAM structure needs to be defined. I am not totally
		sure why, really, but the stack does use some of the fields.
		We do it here, everytime, may be too often, really.
		*/
		NV_RAM_ptr = &My_NV_RAM;

		if (gSeqPowerSaveMode != 0) {
			// Non ordinary setup. - 2 MHZ ordinary, just keep some clock to 
			// we shut it off.
			ICGFLTL = 0x11;
			ICGFLTU = 0x00;		
			return;
		}
		
		// Ordinary setup
		for (;;) {
			// Setup Abel (radio) clock, based on values in NV_RAM.
			ABEL_WRITE(ABEL_regA, NV_RAM_ptr->Abel_Clock_Out_Setting);
			// Wait for clock to settle.
			asm("nop");
			asm("nop");
			asm("nop");
			asm("nop");
			asm("nop");
			asm("nop");
			/* Change to Abel clock */
			ICGC2 = NV_RAM_ptr->NV_ICGC2; 
			ICGC1 = NV_RAM_ptr->NV_ICGC1;
    
			// Wait for clock to settle.
			asm("nop");
			asm("nop");
			asm("nop");
			asm("nop");
			asm("nop");
			asm("nop");

			// Wait for clock to lock (copied from Freescale example code!)
			loopCounter = 100;
			while(((ICGS1 & ICG_FLL_LOCKED) != ICG_FLL_LOCKED) && loopCounter-- > 0);
 
			// Check exit condition
			if((ICGS1 & ICG_FLL_LOCKED) == ICG_FLL_LOCKED)
				break; // Clock is locked - get out of for loop
		}
	};

	/* ********************************************************************** */
	/**
	 * Lost clock handler. 
	 *
	 * <p>When we lose the clock, we call ICG_Setup. If we have requested 
	 * doze through the ASP layer, ICG_Setup will handle it.</p>
	 */
	/* ********************************************************************** */
	/* Lost clock handler */
	TOSH_SIGNAL(ICG) {
		ICGS1 |= 0x01; /* Clear lost clock interrupt */
		/* asm("bgnd");
		call Leds.yellowToggle(); 
		call Leds.redToggle();  */
		ICG_Setup();
	}

	/* *************************************************************************/
	/**
	 * Initialise the MAC layer.
	 *
	 * <p>Note: This code is largely based on guesses, as Freescale do
	 * not have any solid documentation on how to initialize the
	 * stack. Yup, that is right. No info. Look in the obfuscated
	 * example code instead, try if you can make any sense out of
	 * it. :-( (P.S. Later got a lot of help from one of their
	 * engineers - code should be correct.)</p>
	 *
	 * <p>Because I know nothing (nuthin) about the functions, I do not
	 * know if it is safe to call this function multiple times. Probably not, 
	 * because we mess around with the clock.</p>
	 *
	 * @return SUCCESS always.... (sigh)
	 */
	 /**************************************************************************/
	command result_t Control.init()
	{
		/** The NV_RAM structure needs to be defined. I am not totally
		sure why, really, but the stack does use some of the fields.
		We do it here, everytime, may be too often, really.
		*/
		NV_RAM_ptr = &My_NV_RAM;

		/* Configure the PHY HW - or sumptin */
		PHY_HW_Setup();

		// TODO: Set up our own ports? - only needed if PHY_HW_Setup trash some of
		// ours (look in source, if needed).
		// PortSetupSomething();

		// Setup the clock
		ICG_Setup();
    
		// Now, the UART is broken, and must be fixed. 
		// TODO: Perhaps this should be moved to the UART module, that is, 
		// we may not at all use the UART module, so caller to this
		// client should reinit the UART after calling this control module.
		// Also: there are fields in the NV_RAM structure, we could use to 
		// init these registers.
		SCI2BDH = 0x00;
		SCI2BDL = 0x1A; /* 38400 @ 16 MHz BUSCLK */

		/* Set up the radio registers */
		AbelRegisterSetup();
    
		// NB: Do not call "MPIB_Init()", even though it is part of old code examples.
    
		/* Initialize the PHY layer */
		InitializePhy();
		/* Initialize the MAC layer */
		InitializeMac();
      
		/* Return SUCCESS - although we clearly have no idea if that is right */
		return SUCCESS;
	}


	/* ********************************************************************** */
	/**
	 * Console get handler.
	 *
	 * <p>Just a dummy handler, which is required when we include the
	 * Console.</p>
	 *
	 * @param data Ignored
	 * @return SUCCESS always.
	 */
	/* ********************************************************************** */
	async event result_t Console.get(uint8_t data)
	{
		return SUCCESS;
	}


	/* **********************************************************************
	 * The call back functions for the SAPs
	 * *********************************************************************/

	/* ********************************************************************** */
	/**
	 * The ASP call back handler.
	 *
	 * <p>Asynchronous requests or indications from the ASP layer
	 * arrives here. I believe we get a wake indication in here when
	 * e.g. the radio returns from a doze mode.</p>
	 *
	 * <p>TODO: There are no code in here.</p>
	 *
	 * @param msg The message from the ASP layer
	 * @return I think one should return gSuccess_c - no idea.
	 */
	/* ********************************************************************** */
	uint8_t ASP_APP_SapHandler(aspToAppMsg_t *msg) __attribute__((C, spontaneous))
	{
		call Console.print("In ASP_APP_SapHandler - need code in here\n");
		/* TODO: Place code in here */
		return msg->msgType;
	}

	/* ********************************************************************** */
	/**
	 * Handle callbacks from the MLME.
	 *
	 * <p>Based on the type of the parameter, a signal on the relevant
	 * interfaces is sent. The splitting of the code into several
	 * interfaces may be a problem in this context.</p>
	 *
	 * @param msg The messages from the MLME layer
	 * @return gSuccess_c always
	 */
	/* ********************************************************************** */
	uint8_t MLME_NWK_SapHandler(nwkMessage_t *msg) __attribute__((C, spontaneous))
	{
		//asm("bgnd");
		MSG_Queue(&MlmeNwkInputQueue, msg);
		post processMlmeNwk();
		//asm("bgnd");
		return gSuccess_c;
	}
	
	task void processMlmeNwk()
	{
		nwkMessage_t *msg;
		//asm("bgnd");
		if (!MSG_Pending(&MlmeNwkInputQueue))
		{
			//asm("bgnd");
			return;
		}
		msg = MSG_DeQueue(&MlmeNwkInputQueue);
		
		// call Console.print("In MLME_NWK_SapHandler\n");
		/* Note: The msg is freed at the end of this switch statement */
		//asm("bgnd");
		// The work is split into functions due to lack of stack space.
		switch (msg->msgType) {

			// **********************************************************************
			// * Scan confirm
			// **********************************************************************
			case gNwkScanCnf_c: {
				nwkScanCnf(msg);
				break;
			}
			// **********************************************************************
			// * (PIB) set confirm
			// * *********************************************************************
			// This will never happen because set-request is syncronous, and return
			// code from the MSG_Send function is used as return value.
			case gNwkSetCnf_c:
				break;
      
			// **********************************************************************
			// * (PIB) get confirm
			// **********************************************************************
			// This will never happen because get-request is syncronous, and return
			// code from the MSG_Send function is used as return value.
			case gNwkGetCnf_c:
				break;

			// **********************************************************************
			// * Disassociate indication
			// **********************************************************************
			case gNwkDisassociateInd_c:{
				nwkDisassocInd(msg);
				break;
			}
			// **********************************************************************
			// * Disassociate confirm
			// **********************************************************************
			case gNwkDisassociateCnf_c:
				nwkDisassocCnf(msg);
				break;

			// **********************************************************************
			// * PAN start confirm
			// **********************************************************************
			case gNwkStartCnf_c:
				nwkStartCnf(msg);
				break;

			// ***********************************************************************
			// * Associate indication (request from remote device)
			// ***********************************************************************
			case gNwkAssociateInd_c:
				nwkAssocInd(msg);
				break;

			// **********************************************************************
			// * Associate response (confirmation of the association request)
			// **********************************************************************
			case gNwkAssociateCnf_c:
				nwkAssocCnf(msg);
				break;
      
			// JMS: To test MLME_ASSOCIATION.response
			case gNwkCommStatusInd_c:
				nwkCommStatusInd(msg);
				break;

			// Hmm. Do not know how to handle these... - implement and call MLME-COMM-STATUS.indication
			default:
				call Console.print("Unknown message type: 0x");
				call Console.printHex(msg->msgType);
				call Console.print("\n");
		}
		MSG_Free(msg);
		post processMlmeNwk();
	}

	void nwkScanCnf(nwkMessage_t *msg) __attribute__((noinline))
	{
		uint32_t tmp;
		tmp = msg->msgData.scanCnf.unscannedChannels[3];
		tmp = (tmp << 8) + msg->msgData.scanCnf.unscannedChannels[2];
		tmp = (tmp << 8) + msg->msgData.scanCnf.unscannedChannels[1];
		tmp = (tmp << 8) + msg->msgData.scanCnf.unscannedChannels[0];
		//asm("bgnd"); // For the debugger.		
		signal MLME_SCAN.confirm(msg->msgData.scanCnf.status,
		                         msg->msgData.scanCnf.scanType,
		                         tmp,
		                         msg->msgData.scanCnf.resultListSize,
		                         msg->msgData.scanCnf.resList.pEnergyDetectList,
		                         // Pass it in a PANDescriptor for now!
		                         (PANDescriptor_t*)msg->msgData.scanCnf.resList.pPanDescriptorList);
		// Must free the list, ED and PD point to the same (union)
		MSG_Free(msg->msgData.scanCnf.resList.pEnergyDetectList);	
	}
	
	void nwkDisassocInd(nwkMessage_t *msg)
	{
		signal MLME_DISASSOCIATE.indication(*((uint64_t*) msg->msgData.disassociateInd.deviceAddress),
		                                    msg->msgData.disassociateInd.disassociateReason,
		                                    msg->msgData.disassociateInd.securityUse,
		                                    msg->msgData.disassociateInd.aclEntry);
	}

	void nwkDisassocCnf(nwkMessage_t *msg)
	{
		signal MLME_DISASSOCIATE.confirm(msg->msgData.disassociateCnf.status);
	}
	
	void nwkStartCnf(nwkMessage_t *msg)
	{
		signal MLME_START.confirm(msg->msgData.startCnf.status);
	}
	
	void nwkAssocInd(nwkMessage_t *msg)
	{
		signal MLME_ASSOCIATE.indication(*((uint64_t *) msg->msgData.associateInd.deviceAddress),
		                                 msg->msgData.associateInd.capabilityInfo,
		                                 msg->msgData.associateInd.securityUse,
		                                 msg->msgData.associateInd.AclEntry);
	}
	
	void nwkAssocCnf(nwkMessage_t *msg)
	{
		signal MLME_ASSOCIATE.confirm(*((uint16_t *) msg->msgData.associateCnf.assocShortAddress),
		                              msg->msgData.associateCnf.status);
	}
	
	void nwkCommStatusInd(nwkMessage_t *msg)
	{
		call Console.print("gNwkCommStatusInd_c called, status: 0x");
		call Console.printHex(msg->msgData.commStatusInd.status);
		call Console.print("\n");	
	}
	

	/* ********************************************************************** */
	/**
	 * Handle callbacks from the MCPS.
	 *
	 * <p>Based on the type of the parameter, a signal on the relevant
	 * interfaces is sent. The splitting of the code into several
	 * interfaces may be a problem in this context.</p>
	 *
	 * <p>TODO: Actually put some meaningfull code in here...</p>
	 *
	 * @param msg The messages from the MLME layer
	 * @return gSuccess_c always
	 */
	/* ********************************************************************** */
	uint8_t MCPS_NWK_SapHandler(mcpsToNwkMessage_t * msg) __attribute__((C, spontaneous))
	{
		switch (msg->msgType) {
			case gMcpsDataInd_c:
				call Console.print("I got a data-indication!");
				// call MCPS_DATA.indication      
				call Console.print(msg->msgData.dataInd.msdu);
				break;
			default:
				call Console.print("Unknown message type: 0x");
				call Console.printHex(msg->msgType);
				call Console.print("\n");
		}
		//MSG_Free(msg);
		return msg->msgType;
    }
  
	/* **********************************************************************
	 * ACTUAL INTERFACE IMPLEMENTATIONS
	 * *********************************************************************/

	/* **********************************************************************
	 * MLME_DISASSOCIATE INTERFACE
	 * *********************************************************************/

	command void MLME_DISASSOCIATE.request(uint64_t DeviceAddress,
	                                       IEEE_status DisassociateReason,
	                                       bool SecurityEnable)
	{
		mlmeMessage_t * msg = MSG_AllocType(mlmeMessage_t);

		if (!msg) {
			call Console.print("ERROR: MLME_DISASSOCIATE.request: Allocation error\n");
		}
		
		msg->msgType = gMlmeDisassociateReq_c;
		/* Fill in fields */
		memcpy(msg->msgData.disassociateReq.deviceAddress, &DeviceAddress, 8);
		msg->msgData.disassociateReq.securityEnable = SecurityEnable;
		msg->msgData.disassociateReq.disassociateReason = DisassociateReason;

		/* Send it */		
		if(MSG_Send(NWK_MLME, msg) != gSuccess_c) {
			call Console.print("ERROR: MLME_ASSOCIATE.request: Error in send\n");
			return;
		}
		call Console.print("MLME_ASSOCIATE.request sent\n");	
	}

	/* **********************************************************************
	 * MLME_GET INTERFACE
	 * *********************************************************************/
	command void MLME_GET.request(uint8_t PIBAttribute)
	{
		// TODO: value needs to be large enough to hold all kinds of responses.
		uint8_t value=0;
		IEEE_status status;
		mlmeMessage_t *msg;
		msg = MSG_AllocType(mlmeMessage_t);
		if(!msg) {
			call Console.print("ERROR: MLME_GET.request: Allocation error\n");
		}
		msg->msgType = gMlmeGetReq_c;
		msg->msgData.getReq.pibAttribute = PIBAttribute;
		msg->msgData.getReq.pibAttributeValue = (void*)value;
      
		/* Send the Get request to the MLME. */
		status = MSG_Send(NWK_MLME, msg);
		signal MLME_GET.confirm(status, PIBAttribute, (void*)value);
		MSG_Free(msg);
		
	}

	/* **********************************************************************
	 * MLME_SCAN INTERFACE
	 * *********************************************************************/
	command void MLME_SCAN.request(uint8_t ScanType,
	                               uint32_t ScanChannels,
	                               uint8_t ScanDuration)
	{
		uint8_t i;
		mlmeMessage_t * msg;
		//asm("bgnd");
		msg = MSG_AllocType(mlmeMessage_t);
		if(!msg) {
			call Console.print("ERROR: MLME_START.request: Allocation error\n");
			return;
		}
		msg->msgType = gMlmeScanReq_c;
		msg->msgData.scanReq.scanType = ScanType;
		// Byte ordering: Least significant byte first
/*      msg->msgData.scanReq.scanChannels[0] = ScanChannels & 0xFF;
      msg->msgData.scanReq.scanChannels[1] = (ScanChannels>>8) & 0xFF;
      msg->msgData.scanReq.scanChannels[2] = (ScanChannels>>16) & 0xFF;
      msg->msgData.scanReq.scanChannels[3] = (ScanChannels>>24) & 0xFF;*/
		for (i=0;i<4;i++) {
			msg->msgData.scanReq.scanChannels[i] = (ScanChannels >> (i*8)) & 0xFF;
		}
		msg->msgData.scanReq.scanDuration    = ScanDuration;

		/* Send the Scan request to the MLME. */
		if(MSG_Send(NWK_MLME, msg) != gSuccess_c) {
			call Console.print("ERROR: MLME_SCAN.request: Error in send\n");
			return;
		}
		call Console.print("MLME_SCAN.request sent\n");
		//asm("bgnd");
	}

	/* **********************************************************************
	 * MLME_SET INTERFACE
	 * *********************************************************************/
	command void MLME_SET.request(uint8_t PIBAttribute,
	                              void *PIBAttributeValue)
	{
		uint8_t status;
		mlmeMessage_t * msg;
		msg = MSG_AllocType(mlmeMessage_t);
		if(!msg) {
			call Console.print("ERROR: MLME_SET.request: Allocation error\n");
		}
      
		msg->msgType = gMlmeSetReq_c;
		msg->msgData.setReq.pibAttribute      = PIBAttribute;
		msg->msgData.setReq.pibAttributeValue = PIBAttributeValue;
      
		/* Send the Scan request to the MLME. */
		status = MSG_Send(NWK_MLME, msg);
		signal MLME_SET.confirm(status, PIBAttribute);
		MSG_Free(msg);
	}

	/* ********************************************************************** */
	/**
	 * MLME_START interface.
	 *
	 * <p>Implementation Modelled after the user guide, 3.2.4, see
	 * interface for documentation of paramters, etc.</p>
	 */
	/* ********************************************************************** */
	command void MLME_START.request(uint16_t PANId,
	                                uint8_t  LogicalChannel,
	                                uint8_t  BeaconOrder,
	                                uint8_t  SuperframeOrder,
	                                bool     PANCoordinator,
	                                bool     BatteryLifeExtension,
	                                bool     CoordRealignment,
	                                bool     SecurityEnable)
	{
		mlmeMessage_t * msg;
		msg = MSG_AllocType(mlmeMessage_t);
		if (!msg) {
			call Console.print("ERROR: MLME_START.request: Allocation error\n");
			return;
		}
		msg->msgType = gMlmeStartReq_c;
		// Byte ordering: Least significant byte first
		// Panid, LSB, MSB
		msg->msgData.startReq.panId[0]         = PANId & 0xFF;
		msg->msgData.startReq.panId[1]         = (PANId>>8) & 0xFF;
		msg->msgData.startReq.logicalChannel   = LogicalChannel;
		msg->msgData.startReq.beaconOrder      = BeaconOrder;
		msg->msgData.startReq.superFrameOrder  = SuperframeOrder;
		msg->msgData.startReq.panCoordinator   = PANCoordinator;
		msg->msgData.startReq.batteryLifeExt   = BatteryLifeExtension;
		msg->msgData.startReq.coordRealignment = CoordRealignment;
		msg->msgData.startReq.securityEnable   = SecurityEnable;
		
		if(MSG_Send(NWK_MLME, msg) != gSuccess_c) {
			call Console.print("ERROR: MLME_START.request: Error in send\n");
			return;
		}
		call Console.print("MLME_START.request sent\n");
	}

	/* ********************************************************************** */
	/**
	 * MLME_ASSOCIATE interface - request
	 *
	 * <p>Implementation modelled after the user guide, 3.3.2, see interface for
	 * for documentation of parameters.</p>
	 */
	 /* ********************************************************************** */
	command void MLME_ASSOCIATE.request(uint8_t LogicalChannel,
	                                    uint8_t CoordAddrMode,
	                                    uint16_t CoordPANId,
	                                    uint8_t* CoordAddress,
	                                    uint8_t CapabilityInformation,
	                                    bool SecurityEnable)
	{
		mlmeMessage_t * msg;
		msg = MSG_AllocType(mlmeMessage_t);
		if (!msg) {
			call Console.print("ERROR: MLME_ASSOCIATE.request: Allocation error\n");
		}
		
		msg->msgType = gMlmeAssociateReq_c;
		/* Fill in fields */
		msg->msgData.associateReq.logicalChannel = LogicalChannel;
		msg->msgData.associateReq.coordAddrMode  = CoordAddrMode;
		memcpy(msg->msgData.associateReq.coordPanId, &CoordPANId, 2);
		memcpy(msg->msgData.associateReq.coordAddress, CoordAddress, 8);
		msg->msgData.associateReq.capabilityInfo = CapabilityInformation;
		msg->msgData.associateReq.securityEnable = SecurityEnable;
		/* Send it */
		
		if(MSG_Send(NWK_MLME, msg) != gSuccess_c) {
			call Console.print("ERROR: MLME_ASSOCIATE.request: Error in send\n");
			return;
		}
		call Console.print("MLME_ASSOCIATE.request sent\n");
	}

	/* ********************************************************************** */
	/**
	 * MLME_ASSOCIATE interface - response
	 *
	 * <p>Implementation modelled after the user guide, 3.4, see interface for
	 * for documentation of parameters.</p>
	 *
	 * <p>TODO: This is not currently called.</p>
	 */
	/* ********************************************************************** */
	command void MLME_ASSOCIATE.response (uint64_t DeviceAddress,
	                                      uint16_t AssocShortAddress,
	                                      IEEE_status status,
	                                      bool SecurityEnable)
	{
		mlmeMessage_t * msg;
		msg = MSG_AllocType(mlmeMessage_t);
		if (!msg) {
			call Console.print("ERROR: MLME_ASSOCIATE.response: Allocation error\n");
			return;
		}

		msg->msgType = gMlmeAssociateRes_c;
		/* Fill in fields */
		// TODO: No idea if these hacks hold, byte order, whatnot. no time.
		*((uint64_t *) msg->msgData.associateRes.deviceAddress) = DeviceAddress;
		*((uint16_t *) msg->msgData.associateRes.assocShortAddress) = AssocShortAddress;
		msg->msgData.associateRes.status = status;
		msg->msgData.associateRes.securityEnable = SecurityEnable;
		/* Send it */
		if(MSG_Send(NWK_MLME, msg) != gSuccess_c) {
			call Console.print("ERROR: MLME_ASSOCIATE.response: Error in send\n");
			return;
		}
		call Console.print("MLME_ASSOCIATE.response sent\n");
	}

	/* ********************************************************************** */
	/**
	 * MCPS_DATA interface - request
	 *
	 * <p>Modelled after user guide 3.5.1</p>
	 */
	/* ********************************************************************** */
	command void MCPS_DATA.request(uint8_t SrcAddrMode,
	                               uint16_t SrcPANId,
	                               uint8_t* SrcAddr,
	                               uint8_t DstAddrMode,
	                               uint16_t DstPANId,
	                               uint8_t* DstAddr,
	                               uint8_t msduLength,
	                               uint8_t* msdu,
	                               uint8_t msduHandle,
	                               uint8_t TxOptions)
	{
		nwkToMcpsMessage_t * msg = MSG_AllocType(nwkToMcpsMessage_t);
		if(!msg) {
			call Console.print("ERROR: MCPS_DATA.request: Allocation error\n");
			return;
		}
		
		msg->msgType = gMcpsDataReq_c;
		/* Create the header using coordinator information gained during
		the scan procedure. Also use the short address we were assigned
		by the coordinator during association. */
		msg->msgData.dataReq.srcAddrMode = SrcAddrMode;
		memcpy(msg->msgData.dataReq.srcPanId, &SrcPANId, 2);
		memcpy(msg->msgData.dataReq.srcAddr, SrcAddr, 8);

		msg->msgData.dataReq.dstAddrMode = DstAddrMode;
		memcpy(msg->msgData.dataReq.dstPanId, &DstPANId, 2);
		memcpy(msg->msgData.dataReq.dstAddr, DstAddr, 8);

		msg->msgData.dataReq.msduLength = msduLength;
		memcpy(msg->msgData.dataReq.msdu, msdu, msduLength);
		msg->msgData.dataReq.msduHandle = msduHandle;
      
		msg->msgData.dataReq.txOptions = TxOptions;
      
		if(MSG_Send(NWK_MCPS, msg) != gSuccess_c) {
			call Console.print("ERROR: MCPS_DATA.request: Error in send\n");
			return;
		}
		call Console.print("MCPS_DATA.request sent\n");
	}
  
} /* End of implementation */
