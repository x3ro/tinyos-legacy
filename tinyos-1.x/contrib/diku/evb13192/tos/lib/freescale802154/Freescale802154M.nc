/* $Id: Freescale802154M.nc,v 1.15 2006/09/16 17:52:24 janflora Exp $ */
/* SimpleMac module. Wrapper around Freescale SMAC library.

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
 * @author Esben Zeuthen <zept@diku.dk>
 * @author Jan Flora <janflora@diku.dk>
 */

#include "endianconv.h"

#define MAC_ADDR_LOCATION         0xFDB6

module Freescale802154M {
	provides {
		interface StdControl as Control;
		// MCPS
		interface IeeeIndication<Mcps_DataIndication> as McpsIndicationData;
		interface IeeeRequestConfirm<Mcps_DataRequestConfirm> as McpsRequestConfirmData;
		interface IeeeRequestConfirm<Mcps_PurgeRequestConfirm> as McpsRequestConfirmPurge;
		// MLME
		interface IeeeIndicationResponse<Mlme_AssociateIndicationResponse> as MlmeIndicationResponseAssociate;
		interface IeeeRequestConfirm<Mlme_AssociateRequestConfirm> as MlmeRequestConfirmAssociate;
		interface IeeeIndication<Mlme_BeaconNotifyIndication> as MlmeIndicationBeaconNotify;
		interface IeeeIndication<Mlme_CommStatusIndication> as MlmeIndicationCommStatus;
		interface IeeeIndication<Mlme_DisassociateIndication> as MlmeIndicationDisassociate;
		interface IeeeRequestConfirm<Mlme_DisassociateRequestConfirm> as MlmeRequestConfirmDisassociate;						
		interface IeeeSyncRequestConfirm<Mlme_GetRequestConfirm> as MlmeRequestConfirmGet;
		interface IeeeIndication<Mlme_GtsIndication> as MlmeIndicationGts;		
		interface IeeeRequestConfirm<Mlme_GtsRequestConfirm> as MlmeRequestConfirmGts;
		interface IeeeIndicationResponse<Mlme_OrphanIndicationResponse> as MlmeIndicationResponseOrphan;
		interface IeeeRequestConfirm<Mlme_PollRequestConfirm> as MlmeRequestConfirmPoll;
		interface IeeeRequestConfirm<Mlme_ResetRequestConfirm> as MlmeRequestConfirmReset;
		interface IeeeRequestConfirm<Mlme_RxEnableRequestConfirm> as MlmeRequestConfirmRxEnable;
		interface IeeeRequestConfirm<Mlme_ScanRequestConfirm> as MlmeRequestConfirmScan;
		interface IeeeSyncRequestConfirm<Mlme_SetRequestConfirm> as MlmeRequestConfirmSet;
		interface IeeeRequestConfirm<Mlme_StartRequestConfirm> as MlmeRequestConfirmStart;
		interface IeeeIndication<Mlme_SyncLossIndication> as MlmeIndicationSyncLoss;
		interface IeeeRequest<Mlme_SyncRequest> as MlmeRequestSync;
	}
	uses {
		interface Debug;
	}
}
implementation
{
	#define DBG_LEVEL 1
	#include "Debug.h"
	
	uint8_t *radioMACAddr = (uint8_t*)MAC_ADDR_LOCATION;

	anchor_t MlmeNwkInputQueue;
	anchor_t McpsNwkInputQueue;
	bool mlmeDispatchPosted = FALSE;
	bool mcpsDispatchPosted = FALSE;
	
	Mlme_SetRequestConfirm setPrimitive;
	Mlme_GetRequestConfirm getPrimitive;
	Mlme_ResetRequestConfirm resetPrimitive;
	
	task void processMlmeNwk();
	task void processMcpsNwk();
	task void setConfirm();
	task void getConfirm();
	task void resetConfirm();


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
/*	NV_RAM_Struct_t My_NV_RAM = {
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
#endif // BUS_CLOCK_SEEMS_TO_BE_16 
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
#endif // BUS_CLOCK_SEEMS_TO_BE_16
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
	};*/
	
	#define MLME_REQUEST_STACK_SIZE 2
	// we are able to handle MLME_REQUEST_STACK_SIZE mlme requests at a time
	MlmeRequestConfirm_t* mlmeRequestStack[MLME_REQUEST_STACK_SIZE];
	uint8_t mlmeRequestStackSize = 0;
	
	#define MCPS_REQUEST_STACK_SIZE 5
	// we are able to handle MCPS_REQUEST_STACK_SIZE mlme requests at a time
	McpsRequestConfirm_t* mcpsRequestStack[MCPS_REQUEST_STACK_SIZE];
	uint8_t mcpsRequestStackSize = 0;

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
		//NV_RAM_ptr = &My_NV_RAM;

		if (gSeqPowerSaveMode != 0) {
			// Non ordinary setup. - 2 MHZ ordinary, just keep some clock to 
			// we shut it off.
			ICGFLTL = 0x11;
			ICGFLTU = 0x00;		
			return;
		}
		
		// Ordinary setup
		while (!ICGS1_LOCK) {
			// Setup Abel (radio) clock, based on values in NV_RAM.
			//ABEL_WRITE(ABEL_regA, NV_RAM_ptr->Abel_Clock_Out_Setting);
			// Wait for clock to settle.
			ABEL_WRITE(ABEL_regA, 0x3645);	
		
			// Do it the ugly way.. For some reason, the Freescale code
			// don't like my enterFEEMode function :-(
			busClock = 16000000;	
			ICGC1 = 0x18;
			ICGC2 = 0x20;

			// Wait for clock to lock (copied from Freescale example code!)
			loopCounter = 100;
			while (!ICGS1_LOCK && loopCounter-- > 0);
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
	TOSH_SIGNAL(ICG)
	{
		 // Clear lost clock interrupt
		ICGS1 |= 0x01;
		ICG_Setup();
	}

	/* *************************************************************************/
	/**
	 * Initialize the MAC layer.
	 *
	 * @return SUCCESS always.
	 */
	 /**************************************************************************/
	command result_t Control.init()
	{
		/** The NV_RAM structure needs to be defined. I am not totally
		sure why, really, but the stack does use some of the fields.
		We do it here, everytime, may be too often, really.
		*/
		//NV_RAM_ptr = &My_NV_RAM;

		// Setup the mc13192 radio.
		PHY_HW_Setup();

		// Setup the clock
		ICG_Setup();

		// Set up the radio registers.
		AbelRegisterSetup();
		// AbelRegisterSetup expects HF calibration value in NV_RAM.
		// Since we don't use that, write the right value afterwards.
		ABEL_WRITE(ABEL_reg4, (ABEL_CCA_ENERGY_DETECT_THRESHOLD | ABEL_POWER_COMPENSATION_OFFSET));
    
		// Initialize the PHY & MAC layers. 
		InitializePhy();
		InitializeMac();
      
		// Set the MAC address of the device.
		NTOUHCPY64(radioMACAddr, aExtendedAddress);

		return SUCCESS;
	}

	command result_t Control.start()
	{
		return SUCCESS;
	}
	
	command result_t Control.stop()
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
		DBG_STR("In ASP_APP_SapHandler - need code in here",1);
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
		MSG_Queue(&MlmeNwkInputQueue, msg);
		atomic
		{
			if (!mlmeDispatchPosted) {
				mlmeDispatchPosted = TRUE;
				post processMlmeNwk();
			}
		}
		//DBG_STR("MLME_SAPHandler",1);
		return gSuccess_c;
	}
	
	task void processMlmeNwk()
	{
		nwkMessage_t *msg;
		primMlmeToNwk_t type;
		if (!MSG_Pending(&MlmeNwkInputQueue))
		{
			return;
		}
		msg = MSG_DeQueue(&MlmeNwkInputQueue);
		
		// call ConsoleOut.print("In MLME_NWK_SapHandler\n");

		//asm("bgnd");
		// Could be nice to use a switch statement here.. Were it not for the
		// crappy handling of switch statements by the Metrowerks compiler!!

		type = msg->msgType;
		if (type == gNwkAssociateInd_c) {
			// Indicate that security on response frame has not been set.
			msg->msgType = FALSE;
			signal MlmeIndicationResponseAssociate.indication((MlmeIndicationResponse_t*)msg);
		} else if (type == gNwkAssociateCnf_c) {
			signal MlmeRequestConfirmAssociate.confirm((MlmeRequestConfirm_t*)msg);
		} else if (type == gNwkBeaconNotifyInd_c) {
			signal MlmeIndicationBeaconNotify.indication((MlmeIndicationResponse_t*)msg);
		} else if (type == gNwkCommStatusInd_c) {
			signal MlmeIndicationCommStatus.indication((MlmeIndicationResponse_t*)msg);
		} else if (type == gNwkDisassociateInd_c) {
			signal MlmeIndicationDisassociate.indication((MlmeIndicationResponse_t*)msg);
		} else if (type == gNwkDisassociateCnf_c) {
			signal MlmeRequestConfirmDisassociate.confirm((MlmeRequestConfirm_t*)msg);
		} else if (type == gNwkGtsInd_c) {
			signal MlmeIndicationGts.indication((MlmeIndicationResponse_t*)msg);
		} else if (type == gNwkGtsCnf_c) {
			signal MlmeRequestConfirmGts.confirm((MlmeRequestConfirm_t*)msg);
		} else if (type == gNwkOrphanInd_c) {
			// Indicate that security on response frame has not been set.
			msg->msgType = FALSE;
			signal MlmeIndicationResponseOrphan.indication((MlmeIndicationResponse_t*)msg);
		} else if (type == gNwkPollCnf_c) {
			signal MlmeRequestConfirmPoll.confirm((MlmeRequestConfirm_t*)msg);
		} else if (type == gNwkRxEnableCnf_c) {
			signal MlmeRequestConfirmRxEnable.confirm((MlmeRequestConfirm_t*)msg);
		} else if (type == gNwkScanCnf_c) {
			signal MlmeRequestConfirmScan.confirm((MlmeRequestConfirm_t*)msg);
		} else if (type == gNwkStartCnf_c) {
			signal MlmeRequestConfirmStart.confirm((MlmeRequestConfirm_t*)msg);
		} else if (type == gNwkSyncLossInd_c) {
			signal MlmeIndicationSyncLoss.indication((MlmeIndicationResponse_t*)msg);
		} else if (type == gNwkSetCnf_c) {
			// This will never happen because set-request is syncronous
		} else if (type == gNwkResetCnf_c) {
			// this never happens because freescale reset is synchronous
		} else if (type == gNwkGetCnf_c) {
			// This will never happen because get-request is syncronous
		} else {
			DBG_STR("Unknown message type:",1);
			DBG_INT(type,1);
		}

		//MSG_Free(msg);
		
		if (MSG_Pending(&MlmeNwkInputQueue))
		{
			post processMlmeNwk();
		} else {
			mlmeDispatchPosted = FALSE;
		}
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
		MSG_Queue(&McpsNwkInputQueue, msg);
		atomic {
			if (!mcpsDispatchPosted) {
				mcpsDispatchPosted = TRUE;
				post processMcpsNwk();
			}
		}
		//asm("bgnd");
		//DBG_STR("MCPS_SAPHandler",1);
		return gSuccess_c;
	}
	
	task void processMcpsNwk()
	{
		mcpsToNwkMessage_t *msg;
		primMlmeToNwk_t type;
		
		if (!MSG_Pending(&McpsNwkInputQueue))
		{
			return;
		}
		
		msg = MSG_DeQueue(&McpsNwkInputQueue);
		type = msg->msgType;

		if (type == gMcpsDataInd_c) {
			McpsIndication_t *indication = (McpsIndication_t*)msg;
			// We use the msgType field to indicate if destruction of
			// the primitive is allowed.
			indication->msg.msgType = TRUE;
			signal McpsIndicationData.indication(indication);
		} else if (type == gMcpsDataCnf_c) {
			signal McpsRequestConfirmData.confirm((McpsRequestConfirm_t*)msg);
		} else {
			DBG_STR("Unknown message type:",1);
			DBG_INT(msg->msgType,1);
		}
		MSG_Free(msg);
		
		if (MSG_Pending(&McpsNwkInputQueue)) {
			post processMcpsNwk();
		} else {
			mcpsDispatchPosted = FALSE;
		}
	}


	/* **********************************************************************
	 * INTERFACE IMPLEMENTATIONS
	 * *********************************************************************/
	
	command result_t McpsRequestConfirmData.request(Mcps_DataRequestConfirm request)
	{		
		if(MSG_Send(NWK_MCPS, request) != gSuccess_c) {
			return FAIL;
		}
		return SUCCESS;
	}

	command result_t McpsRequestConfirmPurge.request(Mcps_PurgeRequestConfirm request)
	{
		if(MSG_Send(NWK_MCPS, request) != gSuccess_c) {
			return FAIL;
		}
		return SUCCESS;
	}
	
	/***************************
	 *   Default MCPS events   *
	 ***************************/

	default event void McpsRequestConfirmData.confirm(Mcps_DataRequestConfirm confirm)
	{
		DBG_STR("WARNING: Unhandled McpsRequestConfirmData.confirm",1);
	}

	default event void McpsRequestConfirmPurge.confirm(Mcps_PurgeRequestConfirm confirm)
	{
		DBG_STR("WARNING: Unhandled McpsRequestConfirmPurge.confirm",1);
	}	
	
	/**********************************************************
	** MLME
	***********************************************************/
	
	command result_t MlmeRequestConfirmAssociate.request(Mlme_AssociateRequestConfirm request)
	{
		if(MSG_Send(NWK_MLME, request) != gSuccess_c) {
			return FAIL;
		}
		return SUCCESS;
	}

	command result_t MlmeIndicationResponseAssociate.response( Mlme_AssociateIndicationResponse response )
	{
		response->msg.response.msgType = gMlmeAssociateRes_c;
		if(MSG_Send(NWK_MLME, response) != gSuccess_c) {
			return FAIL;
		}
		return SUCCESS;
	}
	
	command result_t MlmeRequestConfirmDisassociate.request(Mlme_DisassociateRequestConfirm request)
	{
		if(MSG_Send(NWK_MLME, request) != gSuccess_c) {
			return FAIL;
		}
		return SUCCESS;
	}

	command Mlme_GetRequestConfirm MlmeRequestConfirmGet.request(Mlme_GetRequestConfirm request)
	{
		uint8_t pibAttribute = ((MlmeRequestConfirmGetSet_t*)request)->primitive.msg.request.msgData.getReq.pibAttribute;
		uint8_t *pibAttributeValue = ((MlmeRequestConfirmGetSet_t*)request)->primitive.msg.request.msgData.getReq.pibAttributeValue;
		getPrimitive = request;
		((MlmeRequestConfirmGetSet_t*)request)->primitive.msg.confirm.msgData.getCnf.status = MSG_Send(NWK_MLME, &(request->primitive));
		((MlmeRequestConfirmGetSet_t*)request)->primitive.msg.confirm.msgData.getCnf.pibAttribute = pibAttribute;
		((MlmeRequestConfirmGetSet_t*)request)->primitive.msg.confirm.msgData.getCnf.pibAttributeValue = pibAttributeValue;
						
		post getConfirm();
		return getPrimitive;
	}
	
	command result_t MlmeRequestConfirmGts.request(Mlme_GtsRequestConfirm request)
	{
		if(MSG_Send(NWK_MLME, request) != gSuccess_c) {
			return FAIL;
		}
		return SUCCESS;
	}

	command result_t MlmeIndicationResponseOrphan.response( Mlme_OrphanIndicationResponse response )
	{
		response->msg.response.msgType = gMlmeOrphanRes_c;
		if(MSG_Send(NWK_MLME, response) != gSuccess_c) {
			return FAIL;
		}
		return SUCCESS;
	}
		
	command result_t MlmeRequestConfirmPoll.request(Mlme_PollRequestConfirm request)
	{
		if(MSG_Send(NWK_MLME, request) != gSuccess_c) {
			return FAIL;
		}
		return SUCCESS;
	}

	command result_t MlmeRequestConfirmReset.request(Mlme_ResetRequestConfirm request)
	{
		resetPrimitive = request;
		((MlmeRequestConfirm_t*)request)->msg.confirm.msgData.resetCnf.status = MSG_Send(NWK_MLME, request);
		
		post resetConfirm();
		return SUCCESS;
	}

	command result_t MlmeRequestConfirmRxEnable.request(Mlme_RxEnableRequestConfirm request)
	{
		if(MSG_Send(NWK_MLME, request) != gSuccess_c) {
			return FAIL;
		}
		return SUCCESS;
	}

	command result_t MlmeRequestConfirmScan.request(Mlme_ScanRequestConfirm request)
	{
		if(MSG_Send(NWK_MLME, request) != gSuccess_c) {
			return FAIL;
		}
		return SUCCESS;
	}

	command Mlme_SetRequestConfirm MlmeRequestConfirmSet.request(Mlme_SetRequestConfirm request)
	{
		uint8_t pibAttribute;
		setPrimitive = request;
		pibAttribute = ((MlmeRequestConfirmGetSet_t*)request)->primitive.msg.request.msgData.setReq.pibAttribute;
		((MlmeRequestConfirmGetSet_t*)request)->primitive.msg.confirm.msgData.setCnf.status = MSG_Send(NWK_MLME, &(request->primitive));
		((MlmeRequestConfirmGetSet_t*)request)->primitive.msg.confirm.msgData.setCnf.pibAttribute = pibAttribute;
			
		post setConfirm();
		return setPrimitive;
	}

	command result_t MlmeRequestConfirmStart.request(Mlme_StartRequestConfirm request)
	{
		if( MSG_Send(NWK_MLME, request) != gSuccess_c) {
			return FAIL;
		}
		return SUCCESS;
	}

	command result_t MlmeRequestSync.request(Mlme_SyncRequest request)
	{
		if(MSG_Send(NWK_MLME, request) != gSuccess_c) {
			return FAIL;
		}
		return SUCCESS;
	}


	task void setConfirm()
	{
		signal MlmeRequestConfirmSet.confirm(setPrimitive);
	}
	
	task void getConfirm()
	{
		signal MlmeRequestConfirmGet.confirm(getPrimitive);
	}
	
	task void resetConfirm()
	{
		signal MlmeRequestConfirmReset.confirm(resetPrimitive);
	}
	
	default event void McpsIndicationData.indication(Mcps_DataIndication indication)
	{
		DBG_STR("WARNING: Unhandled McpsIndicationData.indication",1);
	}

	/***************************
	 *   Default MLME events   *
	 ***************************/

	default event void MlmeRequestConfirmAssociate.confirm(Mlme_AssociateRequestConfirm confirm)
	{
		DBG_STR("WARNING: Unhandled MlmeRequestConfirmAssociate.confirm",1);
	}
	
	default async event void MlmeIndicationResponseAssociate.indication(Mlme_AssociateIndicationResponse indication)
	{
		DBG_STR("WARNING: Unhandled MlmeIndicationResponseAssociate.indication",1);
	}

	default event void MlmeIndicationBeaconNotify.indication(Mlme_BeaconNotifyIndication indication)
	{
		DBG_STR("WARNING: Unhandled MlmeIndicationBeaconNotify.indication",1);
	}
	
	default event void MlmeIndicationCommStatus.indication(Mlme_CommStatusIndication indication)
	{
		DBG_STR("WARNING: Unhandled MlmeIndicationCommStatus.indication",1);
	}

	default event void MlmeRequestConfirmDisassociate.confirm(Mlme_DisassociateRequestConfirm confirm)
	{
		DBG_STR("WARNING: Unhandled MlmeRequestConfirmDisassociate.confirm",1);
	}
	
	default event void MlmeIndicationDisassociate.indication(Mlme_DisassociateIndication indication)
	{
		DBG_STR("WARNING: Unhandled MlmeIndicationDisassociate.indication",1);
	}

	default event void MlmeRequestConfirmGts.confirm(Mlme_GtsRequestConfirm confirm)
	{
		DBG_STR("WARNING: Unhandled MlmeRequestConfirmGts.confirm",1);
	}
	
	default event void MlmeIndicationGts.indication(Mlme_GtsIndication indication)
	{
		DBG_STR("WARNING: Unhandled MlmeIndicationGts.indication",1);
	}
	
	default async event void MlmeIndicationResponseOrphan.indication(Mlme_OrphanIndicationResponse indication)
	{
		DBG_STR("WARNING: Unhandled MlmeIndicationResponseOrphan.indication",1);
	}

	default event void MlmeRequestConfirmPoll.confirm(Mlme_PollRequestConfirm confirm)
	{
		DBG_STR("WARNING: Unhandled MlmeRequestConfirmPoll.confirm",1);
	}

	default event void MlmeRequestConfirmReset.confirm(Mlme_ResetRequestConfirm confirm)
	{
		DBG_STR("WARNING: Unhandled MlmeRequestConfirmReset.confirm",1);
	}

	default event void MlmeRequestConfirmRxEnable.confirm(Mlme_RxEnableRequestConfirm confirm)
	{
		DBG_STR("WARNING: Unhandled MlmeRequestConfirmRxEnable.confirm",1);
	}

	default event void MlmeRequestConfirmScan.confirm(Mlme_ScanRequestConfirm confirm)
	{
		DBG_STR("WARNING: Unhandled MlmeRequestConfirmScan.confirm",1);
	}

	default event void MlmeRequestConfirmSet.confirm(Mlme_SetRequestConfirm confirm)
	{
		DBG_STR("WARNING: Unhandled MlmeRequestConfirmSet.confirm",1);
	}

	default event void MlmeRequestConfirmStart.confirm(Mlme_StartRequestConfirm confirm)
	{
		DBG_STR("WARNING: Unhandled MlmeRequestConfirmStart.confirm",1);
	}

	default event void MlmeIndicationSyncLoss.indication(Mlme_SyncLossIndication indication)
	{
		DBG_STR("WARNING: Unhandled MlmeIndicationSyncLoss.indication",1);
	}

} /* End of implementation */
