/*
    ConsoleTest program - tests Console module somewhat.
    Copyright (C) 2002 Mads Bondo Dydensborg <madsdyd@diku.dk>

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



/**
 * This module tests the Console implementation.
 * 
 * <p>The Console module is debug tool only and should _NOT_ be used in
 * serious applications. It breaks the async. command/event model of
 * tinyos and is ugly in general.</p> */
module TestConsoleM
{ 
	provides
	{
		interface StdControl;
	}
	uses
	{
		interface ConsoleInput as ConsoleIn;
		interface ConsoleOutput as ConsoleOut;
		interface Leds;
		interface Timer;
	}
}
implementation
{
	// Used to keep the command the user types in
	char buf[200];
	char * bufpoint;
	uint8_t countcmd;
	uint16_t countadd;
	uint32_t countmore;

	task void flood();
	task void commandParserTask();
	task void prompt();
	
	command result_t StdControl.init()
	{
		dbg(DBG_USR1, "Initializing ......\n");
		atomic {
			bufpoint = buf;
			*bufpoint = 0;
		}
		countcmd = 0;
		countadd = 0x4200;
		countmore = 0x42A04300;
		return call Leds.init();
	}

	command result_t StdControl.start()
	{
		uint8_t array[4];

		array[0] = 0xa0;
		array[1] = 0x0a;
		array[2] = 42;
		array[3] = 0x42;

		// Test some print statemets
		call ConsoleOut.print("\n\rTinyOS Command Interprenter 0.01b\n\r");
		call ConsoleOut.print("Version : ");
		call ConsoleOut.dumpHex(array, 4, "-.-");
		call ConsoleOut.print("\n\r");
		call ConsoleOut.print("[root@evb13192 / ");
		call ConsoleOut.printHex(countcmd++);
		call ConsoleOut.print("]# ");
		post prompt();
		//call Leds.greenToggle();
		call Timer.start(TIMER_REPEAT, 2000);
		return SUCCESS;
	}

	command result_t StdControl.stop()
	{
		dbg(DBG_USR1, "Stopping ......\n");
		return SUCCESS;
	}

	/** Help function, does string compare */
	int strcmp(const char * a, const char * b)
	{
		while (*a && *b && *a == *b) { ++a; ++b; };
		return *a - *b;
	}

	task void prompt()
	{
		call ConsoleOut.print("[root@evb13192 / ");
		call ConsoleOut.printHex(countcmd++);
		call ConsoleOut.print("/");
		call ConsoleOut.printHexword(countadd++);
		call ConsoleOut.print("/");
		call ConsoleOut.printHexword(0x1122);
		call ConsoleOut.print("/");
		call ConsoleOut.printHexword(0x3344);
		call ConsoleOut.print("/");
		call ConsoleOut.printHexword(0xFFEE);
		call ConsoleOut.print("/");
		call ConsoleOut.printHexlong(0xFFEEDDCC);
		call ConsoleOut.print("/");
		call ConsoleOut.printHexlong(0x11223344);
		call ConsoleOut.print("/");
		call ConsoleOut.printHexlong(countmore++);
		call ConsoleOut.print("]# ");
		//call Leds.redToggle();
	}

	task void flood()
	{
		int i;
		call ConsoleOut.print("FLOOD\n");
		for (i = 0; i < 256; i++) {
			call ConsoleOut.printHex(i);
		}
		call ConsoleOut.print("\nFLOOD ENDED\n");
	}

	task void commandParserTask()
	{
		if (0 == strcmp("flood", buf)) {
			//call ConsoleOut.print("\n\rFlood detected\n\r");
			post flood();
		} else {
			call ConsoleOut.print("\n\rtosh: ");
			call ConsoleOut.print(buf);
			call ConsoleOut.print(": command not found\n\r");
		}
		atomic {
			bufpoint = buf;
			*bufpoint = 0;
		}
		post prompt();
	}

	async event result_t ConsoleIn.get(uint8_t theData)
	{
		if (theData == '\n') {
			post commandParserTask();
		} else {
			atomic {
				*bufpoint = theData;
				bufpoint++;
				*bufpoint = 0;
			}
		}
		return SUCCESS;
	}
	
	event result_t Timer.fired()
	{
		call Leds.redToggle();
		return SUCCESS;
	}
}
