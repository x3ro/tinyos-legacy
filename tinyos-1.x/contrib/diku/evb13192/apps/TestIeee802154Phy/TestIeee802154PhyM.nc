#include <macTypes.h>
#include <phyTypes.h>

module TestIeee802154PhyM
{
	provides
	{
		interface StdControl;
	}
	
	uses
	{
		interface ConsoleOutput as ConsoleOut;

		interface IeeePhyPibAttribute;
		interface IeeePhySdu;

		// PLME
		interface PlmeCcaRequestConfirm;
		interface IeeeRequestConfirm<Plme_CcaRequestConfirm> as PlmeRequestConfirmCca;

		interface PlmeEdRequestConfirm;
		interface IeeeRequestConfirm<Plme_EdRequestConfirm> as PlmeRequestConfirmEd;
		
		interface PlmeGetRequestConfirm;
		interface IeeeRequestConfirm<Plme_GetRequestConfirm> as PlmeRequestConfirmGet;
		
		interface PlmeSetRequestConfirm;
		interface IeeeRequestConfirm<Plme_SetRequestConfirm> as PlmeRequestConfirmSet;
				
		interface PlmeSetTrxStateRequestConfirm;
		interface IeeeRequestConfirm<Plme_SetTrxStateRequestConfirm> as PlmeRequestConfirmSetTrxState;

		// PD
		interface PdDataRequestConfirm;
		interface IeeeRequestConfirm<Pd_DataRequestConfirm> as PdRequestConfirmData;
		
		interface PdDataIndication;
		interface IeeeIndication<Pd_DataIndication> as PdIndicationData;
	}
}

implementation
{
	bool transmitter = FALSE;

	// Forward declarations.
	void pdRequestConfirmDataTest();
	void plmeRequestConfirmCcaTest();
	void plmeRequestConfirmEdTest();
	void plmeRequestConfirmGetTest();
	void plmeRequestConfirmSetTest();
	void plmeRequestConfirmSetTrxStateTest(uint8_t state);

	command result_t StdControl.init()
	{
		return SUCCESS;
	}

	command result_t StdControl.start()
	{
		call ConsoleOut.print("TestIeee802154PhyM: StdControl.start\n");
		
		if (transmitter) {
			// Transmitter code.
			plmeRequestConfirmSetTrxStateTest(PHY_TX_ON);
			pdRequestConfirmDataTest();
		} else {
			// Receiver code.
			plmeRequestConfirmSetTrxStateTest(PHY_RX_ON);
			//plmeRequestConfirmEdTest();
			//plmeRequestConfirmCcaTest();
			//plmeRequestConfirmSetTest();
			//plmeRequestConfirmGetTest();
		}
	
		return SUCCESS;
	}

	command result_t StdControl.stop()
	{
		return SUCCESS;
	}

	void plmeRequestConfirmCcaTest()
	{
		Plme_CcaRequestConfirm request;	
		
		if(!call PlmeCcaRequestConfirm.create(&request))
		{
			call ConsoleOut.print("plmeRequestConfirmCcaTest: Allocation failed\n");
			return;
		}
		
		call PlmeRequestConfirmCca.request(request);
	}
	
	void plmeRequestConfirmEdTest()
	{
		Plme_EdRequestConfirm request;	
		
		if(!call PlmeEdRequestConfirm.create(&request))
		{
			call ConsoleOut.print("plmeRequestConfirmEdTest: Allocation failed\n");
			return;
		}
		
		call PlmeRequestConfirmEd.request(request);
	}

	void plmeRequestConfirmGetTest()
	{
		Plme_GetRequestConfirm request;
		
		if(!call PlmeGetRequestConfirm.create(&request))
		{
			call ConsoleOut.print("plmeRequestConfirmGetTest: Allocation failed\n");
			return;
		}
		
		call PlmeGetRequestConfirm.setPibAttribute(request, IEEE802154_phyCurrentChannel);

		call PlmeRequestConfirmGet.request(request);
	}

	void plmeRequestConfirmSetTest()
	{
		Plme_SetRequestConfirm request;
		Ieee_PhyPibAttribute attribute;
		
		if(!call IeeePhyPibAttribute.create(&attribute))
		{
			call ConsoleOut.print("plmeRequestConfirmSetTest: Allocation failed\n");
			return;
		}
		
		call IeeePhyPibAttribute.setPhyCurrentChannel(attribute, 0x0C);
		
		if(!call PlmeSetRequestConfirm.create(&request))
		{
			call ConsoleOut.print("plmeRequestConfirmGetTest: Allocation failed\n");
			return;
		}
		
		call PlmeSetRequestConfirm.setPibAttribute(request, attribute);
	
		call PlmeRequestConfirmSet.request(request);
	}

	void plmeRequestConfirmSetTrxStateTest(uint8_t state)
	{
		Plme_SetTrxStateRequestConfirm request;	
		
		if(!call PlmeSetTrxStateRequestConfirm.create(&request))
		{
			call ConsoleOut.print("plmeRequestConfirmSetTrxStateTest: Allocation failed\n");
			return;
		}
			
		call PlmeSetTrxStateRequestConfirm.setState(request, state);
		
		call PlmeRequestConfirmSetTrxState.request(request);
	}

	void pdRequestConfirmDataTest()
	{
		char* testBuffer = "Hello World!";
		Ieee_Psdu sendPsdu;
		Pd_DataRequestConfirm request;

		call IeeePhySdu.create(&sendPsdu);
		call IeeePhySdu.setPayload(sendPsdu, (uint8_t*)testBuffer);
		call IeeePhySdu.setPayloadLen(sendPsdu, 13);

    		// Create request
		call PdDataRequestConfirm.create(&request);    	
		call PdDataRequestConfirm.setPsdu(request, sendPsdu);

    		call PdRequestConfirmData.request(request);
	}
	


	// PLME
	event void PlmeRequestConfirmCca.confirm(Plme_CcaRequestConfirm confirm)
	{
		Ieee_PhyStatus status = call PlmeCcaRequestConfirm.getStatus(confirm);
		
		call ConsoleOut.print("TestIeee802154PhyM: PlmeRequestConfirmCca.confirm\n");
		call ConsoleOut.print("\t[status = ");
		call ConsoleOut.printHex(status);
		call ConsoleOut.print("]\n");
	}

	event void PlmeRequestConfirmEd.confirm(Plme_EdRequestConfirm confirm)
	{
		Ieee_PhyStatus status = call PlmeEdRequestConfirm.getStatus(confirm);
		uint8_t energyLevel = call PlmeEdRequestConfirm.getEnergyLevel(confirm);

		call ConsoleOut.print("TestIeee802154PhyM: PlmeRequestConfirmEd.confirm\n");
		call ConsoleOut.print("\t[status=");
		call ConsoleOut.printHex(status);
		call ConsoleOut.print(", EnergyLevel=");
		call ConsoleOut.printHex(energyLevel);
		call ConsoleOut.print("]\n");
	}

	event void PlmeRequestConfirmGet.confirm(Plme_GetRequestConfirm confirm)
	{
		Ieee_PhyPibAttribute attribute;
		uint8_t status = call PlmeGetRequestConfirm.getStatus(confirm);

		call ConsoleOut.print("TestIeee802154PhyM: PlmeRequestConfirmGet.confirm\n");
		
		if(!call IeeePhyPibAttribute.create(&attribute))
		{
			call ConsoleOut.print("PlmeRequestConfirmGet: Allocation failed\n");
			return;
		}
		
		if(!call PlmeGetRequestConfirm.getPibAttribute(confirm, attribute))
		{
			call ConsoleOut.print("PlmeRequestConfirmGet: Get PIB attribute failed\n");
			return;
		}

		call ConsoleOut.print("\t[status=");
		call ConsoleOut.printHex(status);
		call ConsoleOut.print(", pibAttribute=");
		call ConsoleOut.printHex(call IeeePhyPibAttribute.getPibAttributeType(attribute));
		call ConsoleOut.print(", pibAttributeValue=");
		
		switch(call IeeePhyPibAttribute.getPibAttributeType(attribute))
		{
			case IEEE802154_phyCurrentChannel:
				call ConsoleOut.printHex(call IeeePhyPibAttribute.getPhyCurrentChannel(attribute));
				break;
		};

		call ConsoleOut.print("]\n");
	}

	event void PlmeRequestConfirmSet.confirm(Plme_SetRequestConfirm confirm)
	{
		call ConsoleOut.print("TestIeee802154PhyM: PlmeRequestConfirmSet.confirm\n");
		call ConsoleOut.print("\t[status=");
		call ConsoleOut.printHex(call PlmeSetRequestConfirm.getStatus(confirm));
		call ConsoleOut.print(", pibAttribute=");
		call ConsoleOut.printHex(call PlmeSetRequestConfirm.getPibAttribute(confirm));
		call ConsoleOut.print("]\n");
	}

	event void PlmeRequestConfirmSetTrxState.confirm(Plme_SetTrxStateRequestConfirm confirm)
	{
		Ieee_PhyStatus status = call PlmeSetTrxStateRequestConfirm.getStatus(confirm);

		call ConsoleOut.print("TestIeee802154PhyM: PlmeRequestConfirmSetTrxState.confirm\n");
		call ConsoleOut.print("\t[status=");
		call ConsoleOut.printHex(status);
		call ConsoleOut.print("]\n");
	}

	// PD
	event void PdRequestConfirmData.confirm(Pd_DataRequestConfirm confirm)
	{
		Ieee_PhyStatus status = call PdDataRequestConfirm.getStatus(confirm);

		call ConsoleOut.print("TestIeee802154PhyM: PdRequestConfirmData.confirm\n");
		call ConsoleOut.print("\t[status=");
		call ConsoleOut.printHex(status);
		call ConsoleOut.print("]\n");
	}
	
	event void PdIndicationData.indication(Pd_DataIndication indication)
	{
		Ieee_Psdu recvPsdu = call PdDataIndication.getPsdu(indication);
		call ConsoleOut.print("Got a data indication: ");
		call ConsoleOut.printStr(call IeeePhySdu.getPayload(recvPsdu), call IeeePhySdu.getPayloadLen(recvPsdu));
		call ConsoleOut.print("\n");
		call IeeePhySdu.destroy(recvPsdu);
		call PdDataIndication.destroy(indication);
	}
}
