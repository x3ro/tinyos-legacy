#include <macTypes.h>
#include <Ieee802154Adts.h>
 // TODO: do not include this
#include <macConstants.h>
#include <phyTypes.h>
#include <MacPib.h>
#include <mac.h>
module Test802154M
{
	provides {
		interface StdControl;
	}
	uses {
		interface Synchronize;
		interface BeaconScan;
		interface ConsoleInput as ConsoleIn;
		interface ConsoleOutput as ConsoleOut;
		interface TestTime;
		interface Debug;
	}
}

implementation
{
	#define DBG_LEVEL 1
	#include "Debug.h"
	
	char* testBuffer = "Hello World!";
	uint8_t testBufferLen = 12;
	Ieee_Msdu rcvMsdu;
	
	// The selected logical channel is store in here, initialized to 11
	uint8_t logicalChannel = 11;
	uint8_t *EDList;

	// Global variable used for activty -> association (Yes, ugly, fix it :-)
	Mlme_ScanRequestConfirm scanconfirm;
	panDescriptor_t tmpPan;
	Ieee_PanDescriptor panInfo = &tmpPan;

	// P2P send sender and recipient info
	uint8_t p2pRcptAddr[8] = {0x00, 0x50, 0xC2, 0x37, 0xB0, 0x01, 0x03, 0x02};
	uint8_t p2pSendAddr[8] = {0x00, 0x50, 0xC2, 0x37, 0xB0, 0x01, 0x03, 0x09};

	// Short address we got
	uint16_t panClientShort;
	uint16_t sendToAddr;
	uint16_t tos_local_address;  //This node
	uint16_t beacons = 0;
	
	uint8_t myMsduHandle = 0x01;

    // PAN address used when coordinator.
	uint16_t myPanId = 0xFEDE;

	/** Used to keep the commands the user type in */
	char cmd_input[200];
	char * bufpoint;

	/** Store data from the Console.get event here. */
	char console_data;

	void prompt();
	
	task void help();
	task void info();
	int strcmp(const char * a, const char * b);
	task void handleGet();
 
	command result_t StdControl.init()
	{
		/* Set up our command buffer */
		bufpoint = cmd_input;
		*bufpoint = 0;
		tos_local_address = TOS_LOCAL_ADDRESS;
		return SUCCESS;
	}

	command result_t StdControl.start() { 
		prompt();
		return SUCCESS;
	}

	command result_t StdControl.stop()
	{
		return FAIL;
	}	
	
	event void BeaconScan.done(result_t result, Ieee_PanDescriptor bestPanInfo)
	{
		if ( result == SUCCESS ){
			DBG_STR("Scan succeeded",1);
			panInfo = bestPanInfo;			
		} else {
			DBG_STR("Scan yielded no results",1);
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
	async event result_t ConsoleIn.get(uint8_t data) {
		atomic console_data = data;
		post handleGet();
		return SUCCESS;
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
		call ConsoleOut.print(" has MAC extended address 0x");
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
				call ConsoleOut.print("ascan  pscan sync info help ls\n");
				prompt();
			} else if (0 == strcmp("", cmd_input)) {
				prompt();
			} else if (0 == strcmp("ascan", cmd_input)) {
				call BeaconScan.activeScan();
			} else if (0 == strcmp("pscan", cmd_input)) {
				call BeaconScan.passiveScan();
			} else if (0 == strcmp("help", cmd_input)) {
				post help();
			} else if (0 == strcmp("info", cmd_input)) {
				post info();
			} else if (0 == strcmp("sync", cmd_input)) {
				call Synchronize.track(panInfo);
			} else if (0 == strcmp("watch", cmd_input)) {
				call TestTime.start();
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
