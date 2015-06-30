
/***************************************************************************
MODULE		NetProgX
FILE		Xnp.nc
PURPOSE		In Network Programming/Boot Component Interface

PLATFORM	MICA2
			TOS NesC

REVISION	02mar03	mm	created


==============================================================================
DESCRIPTION

Provides In-Network Programming services to client/application.

There are 2 main phases:
1. Program/code download from network/host via radio.
2. Local reprogram of UP and reboot.

These operations are independent and coordinated with Mote Application (client)
to avoid resource conflicts.


RESOURCES
NP uses 
-EEPROM (External Flash memory).
-GENERIC_COMM / Active Message Handler#47

NOTES
-EEPROM resource is shared by NP and Client. T
Client must release EEPROM resource before acknowledging NP_DOWNLOAD_REQ.
Client must filter/check for propoer (owned) hInstance on all EEPROM signals/event inorder to
discriminate against NP messages. This is a shared wiring.

-Only 1 Program image in EEPROM is currently support.

-Client must INIT and TUNE radio. I.e. establish wireless link.

INTERFACES

-Download Phase
NP_DOWNLOAD_REQ
Signal to Client that an in-network program download operation has been
received (over-air using AM#??).Passes to client planned EEPROM start page
and number of pages to be used to store download program

NP_DOWNLOAD_ACK
Acknowledge from Client that NP download operation can/cannot proceed with
download.

NP_DOWNLOAD_DONE
Signal to Client that in-network program download operation has completed.
Supplies actual EEROM Start Page, NofPages used to store downloaded program
Client is now responsible for maintaining integrity of code image downloaded
into EEPROM (i.e. must not overwrite/modify the section of EEPROM)


-Reprogram Phase
NP_REPROG_MSG
Signal to client that a in-network reprogram/reboot message has been received

NP_REPROG_REQ
Command from client to initiate a reprogram/reboot operation.
Client passes ProgramID which is matched with ID found in EEPROM. If match
UP reprogramming/reboot operation is started. Client should release all 
resources/ before issuing request.
===============================================================================
******************************************************************************/

interface Xnp
{
 command result_t NPX_DOWNLOAD_ACK(uint8_t cAck ); 
 command result_t NPX_SENDSTATUS(uint16_t wAck );
 command result_t NPX_ISP_REQ(uint16_t wProgID, uint16_t wEEPageStart, uint16_t nwProgID);
 command result_t NPX_SET_IDS();
 event result_t NPX_DOWNLOAD_REQ(uint16_t wProgramID, uint16_t wEEStartP, uint16_t wEENofP);
 event result_t NPX_DOWNLOAD_DONE(uint16_t wProgramID, uint8_t bRet, uint16_t wEENofP);
}

